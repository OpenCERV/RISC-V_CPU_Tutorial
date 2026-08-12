# Backend Physical Design Guide

A practical reference for RTL-to-GDS flows. Tool-agnostic — applies to ECC, OpenLane, OpenROAD, and commercial flows alike.

---

## 1. The Fundamental Relationship: Utilization, Density, and Area

### 1.1 Synthesis area determines everything

Synthesis produces a gate-level netlist. Its **total cell area** (sum of all standard cells + macros) is the denominator for all downstream area calculations:

```
core_area ≈ total_cell_area / core_util
die_area  = core_area + 2 × core_margin × √core_area + margin²
```

If total cell area is 250,000 µm² and you target `core_util = 0.7`:

```
core_area = 250,000 / 0.7 ≈ 357,000 µm²
die_side  = √357,000 ≈ 597 µm
```

Larger core utilization → smaller die → cheaper. But less room for routing.

### 1.2 Utilization vs density

| Parameter | When | What it controls |
|-----------|------|-----------------|
| `core_util` | Floorplan | Die/core size: `core = cell_area / util` |
| `target_density` | Placement | How tightly cells are packed inside the core |

**The golden rule: density ≥ actual utilization.**

If your floorplan produces a core where cells already occupy 87% of the area (actual utilization = 0.87), you cannot set `target_density = 0.8`. The placer will silently raise it — or fail.

**Rule of thumb:** `target_density ≥ actual_utilization + 0.05`. At 0.7 core util with macros, actual utilization is often 0.60–0.75. Density should be 0.65–0.80.

### 1.3 Macros break the simple math

Macros (SRAM, PLL, analog blocks) occupy fixed positions and do not participate in placement optimization. If macros occupy 17% of the core:

```
stdcell_area        = core_area × (core_util − macro_area_fraction)
effective_util      = stdcell_area / (core_area − macro_area)
```

An apparently reasonable `core_util = 0.7` can become `effective_util = 0.85` for the standard-cell region, leaving very little routing whitespace.

---

## 2. Macro Placement

### 2.1 Pin orientation

Macro pins should face **inward** toward the core center, not toward the die edge. Facing the edge creates a pin-access dead zone where no routing layer reaches the pins from outside.

For two identical macros placed top and bottom:
- **Bottom macro:** FS orientation — pins face UP toward center
- **Top macro:** N orientation — pins face DOWN toward center

### 2.2 Edge clearance

Keep macros at least **50 µm** from the die edge. Closer placement starves the space between the macro pins and the I/O ring, making pin access nearly impossible.

### 2.3 Horizontal centering

Center macros horizontally on the die:

```
macro_llx = die_width/2 − macro_width/2
```

### 2.4 Routing channels between macros

Never abut two macros. Leave a routing channel at least 10–20 µm wide between them for signal and power routing.

### 2.5 Macro halo

A keep-out zone around each macro where no standard cells can be placed. Two types:

| Halo type | Purpose | Typical value |
|-----------|---------|---------------|
| Placement halo | Prevents cells near macro edge | 5–10 µm |
| Routing halo | Prevents routing congestion at boundary | 5–10 µm |

Larger halos reduce DRCs near macros but waste area. Start at 10 µm for both, reduce if DRCs allow.

---

## 3. Floorplan Parameters

### 3.1 Aspect ratio

`aspect_ratio = height / width`. 1.0 gives a square die with balanced H/V routing. Ratios > 1.0 (tall) or < 1.0 (wide) can help:
- Fit macros that are much taller than wide
- Align with I/O ring constraints
- Reduce routing congestion in one direction

Downside: the long dimension can become a routing bottleneck.

### 3.2 Core margin

Empty space between the core boundary and the die edge:

```
die_side = core_side + 2 × margin
```

Purpose:
- Room for power rings
- I/O cell placement
- Decoupling capacitance
- Peripheral routing

Typical: 2–10 µm. Too small = congestion at the periphery. Too large = wasted area.

### 3.3 Iteration strategy

**First run: conservative.** Start at `core_util = 0.45–0.55`, `density = 0.50–0.60`. Establish a clean DRC baseline.

**Then tighten incrementally:** +0.05 each run until DRCs spike. **Find the knee** — the density just before routing runtime and violations explode.

---

## 4. Placement

### 4.1 Cell padding

Adds whitespace around every standard cell. Two effects:

| Effect | Mechanism |
|--------|-----------|
| **Good:** Reduces DRCs | Cells have more pin-access space, fewer shorts |
| **Bad:** Increases density | Each cell footprint grows → effective utilization rises |

At `cell_padding_x = 200` (0.2 µm), every cell gets 200 nm of padding per side. Over 70,000 cells, this adds significant area.

Start at 100. Increase if DRCs are pin-access dominated. Reduce if density becomes the bottleneck.

### 4.2 Routability optimization

Enables the placer to consider routing congestion during global placement. Essential for dense designs. Always enable (`routability_opt = 1`).

### 4.3 Congestion metrics

After placement, check:

- **Overflow** (demand/capacity): > 1 means not enough routing tracks. Values approaching 1.0 in the log indicate congestion risk.
- **RUDY utilization maps:** hotspots show where routing demand exceeds supply
- **Pin density maps:** high pin density regions need more routing resources

If overflow is high after placement, routing will be painful. Fix by lowering density or increasing core area.

---

## 5. Clock Tree Synthesis (CTS)

### 5.1 What CTS does

Builds a balanced clock distribution network from the clock source to all sequential elements.

### 5.2 Key metrics

| Metric | Meaning | Target |
|--------|---------|--------|
| **Skew** | Difference in clock arrival between sinks | < 100 ps typical |
| **Latency** | Total clock insertion delay | Design-dependent |
| **Buffer count** | Number of clock buffers inserted | Fewer = lower power |
| **Buffer area** | Total area of clock tree | < 5% of core area |

### 5.3 When CTS fails

If CTS inserts **zero buffers**, the clock isn't being propagated. Check:
- Clock port name matches the SDC
- The clock net is not tied to a constant
- Clock reaches all sequential elements in the netlist

### 5.4 CTS and timing closure

CTS adds delay to the clock path. Setup slack gets **worse** (clock arrives later, less time for data). Hold slack gets **better** (clock arrives later, data held longer). This is why post-CTS STA is critical.

---

## 6. Routing

### 6.1 Layer stack

Typical 6-metal stack:

| Layer | Use |
|-------|-----|
| MET1 | Standard cell pins, follow-pins (power), local interconnect |
| MET2 | Short horizontal routes |
| MET3 | Medium vertical routes |
| MET4 | Long routes, power stripes |
| MET5 | Long routes, power stripes |
| MET6 (RDL) | Redistribution, top-level power |

Configure `route.bottom_layer = MET2`, `route.top_layer = MET5` for standard routing.

### 6.2 Congestion and routing time

Routing time is **nonlinear** with congestion:

| DRC count | Routing time | Interpretation |
|-----------|-------------|----------------|
| < 1,000 | < 5 min | Clean — density is right |
| 1,000–10,000 | 5–20 min | Acceptable — minor hotspots |
| 10,000–50,000 | 20–60 min | Congested — need lower density |
| > 50,000 | > 60 min | Severely congested — redesign floorplan |

Each DRC violation triggers rip-up and reroute iterations. Beyond a threshold, the router enters a combinatorial explosion.

### 6.3 Common DRC types

| Type | Cause | Fix |
|------|-------|-----|
| `cut_short` | Via too short / missing | More cell spacing, especially near macros |
| `metal_short` | Two nets shorted on same layer | Reduce density, add cell padding |
| `parallel_run_length_spacing` | Parallel wires too close for too long | Spread cells, use higher metal layers |
| `minimum_area` | Metal shape too small | Usually filler/PG issue |
| `same_layer_cut_spacing` | Vias too close | Improve pin accessibility |
| `min_hole` | Enclosed area too small | Filler insertion |

---

## 7. Static Timing Analysis (STA)

### 7.1 Timing corners

| Corner | Voltage | Temperature | Used for |
|--------|---------|-------------|----------|
| SS (slow-slow) | V_min | T_max (125°C) | **Setup** checks — worst delay |
| FF (fast-fast) | V_max | T_min (−40°C) | **Hold** checks — best delay |
| TT (typical) | V_nom | 25°C | Initial exploration |

**Always close setup at SS before checking hold at FF.**

### 7.2 Slack

```
required_time = clock_period − clock_uncertainty − setup_time
arrival_time  = clock_latency + max(cell_delays + wire_delays)
slack         = required_time − arrival_time
```

- **Positive slack:** constraint met
- **Zero slack:** exactly met
- **Negative slack:** violation

### 7.3 Fixing setup violations

Setup violations mean the data path is too slow:

1. **Reduce logic depth** — fewer gates between flops
2. **Upsize cells** — larger drivers switch faster
3. **Adjust floorplan** — move related cells closer, reduce wire delay
4. **Lower frequency** — increase clock period (last resort)
5. **Use LVT cells** — faster but higher leakage

### 7.4 Fixing hold violations

Hold violations mean data changes too quickly after the clock edge:

1. **Insert buffers** — add delay to the data path
2. **Upsize hold buffers** — if hold margin is very small
3. **Increase clock skew** — intentional skew can fix hold (but hurts setup)

### 7.5 Clock uncertainty

Models jitter and skew that STA can't predict precisely. Typical: 200–300 ps for 100 MHz designs. Added to the required time to provide margin.

---

## 8. Power Delivery Network (PDN)

### 8.1 Purpose

Distributes VDD and VSS (GND) evenly across the chip. Insufficient PDN → **IR drop** → gates see lower voltage → slower switching → timing failures.

### 8.2 Structure

| Component | Layer | Purpose |
|-----------|-------|---------|
| Rails (follow-pins) | MET1 | Connect to standard cell VDD/VSS pins |
| Stripes | MET4, MET5 | Distribute power across the die |
| Power ring | MET4–5 | Peripheral VDD/VSS distribution |
| Via stacks | MET1→MET5 | Vertical power delivery |

### 8.3 What to check

- PDN coverage is uniform (no large unpowered regions)
- Stripe pitch is reasonable (12–20 µm typical for 55 nm)
- Macro power pins are connected to the grid

---

## 9. Filler Cells

### 9.1 Why fillers are required

After routing, the layout has gaps between standard cells. Fillers:
- **Maintain N-well/P-well continuity** — DRC requirement
- **Insert decoupling capacitance** — reduces dynamic IR drop
- **Satisfy density rules** — some processes have minimum density requirements

### 9.2 Filler types

| Type | Purpose |
|------|---------|
| FILLER1, FILLER2 | Minimal width gap fillers |
| FILLCAP4, FILLCAP8, FILLCAP16, FILLCAP32 | Decap fillers (larger = more capacitance) |
| FILLTAP | Well tap (N-well to VDD, P-well to VSS) — required at regular intervals |

---

## 10. RC Extraction and Post-Layout STA

### 10.1 RCX (Parasitic Extraction)

After routing, extract resistance (R) and capacitance (C) from the physical wires. Produces a **SPEF** (Standard Parasitic Exchange Format) file.

Wire delay after RCX is **much more accurate** than pre-route wireload models. Setup violations that didn't appear in pre-route STA often show up after RCX.

### 10.2 Post-layout STA

Read the post-route netlist + SPEF + SDC. Run both setup and hold analysis. This is the **signoff** timing check.

### 10.3 SDF (Standard Delay Format)

Annotated gate-level netlist with actual delays. Used for:
- Gate-level simulation (GLS)
- Power analysis
- Final signoff

---

## 11. Iteration Workflow

```
Run 1: core_util=0.50, density=0.55, cell_padding=0
    → Baseline. Expect clean routing, < 1K DRCs.

Run 2: core_util=0.55, density=0.60
    → Tighten. Check DRC count and runtime.

Run 3: core_util=0.60, density=0.65
    → Continue tightening. Watch for DRC spikes.

    ...

Run N: DRCs > 10K → back off by 0.05 on both.
    → This is your design's knee.
```

**Golden rule:** don't chase signoff DRC on the first parameter set. Explore the space, find the knee, then refine.

---

## 12. Quick Reference: Parameter Relationships

| If you want to... | Adjust... | Side effect |
|-------------------|-----------|-------------|
| Reduce DRCs | Lower density, add cell padding | Larger die, higher cost |
| Reduce area | Higher core_util | More congestion, more DRCs |
| Fix setup | Upsize cells, reduce logic depth | More area, more power |
| Fix hold | Insert buffers | More area, trivial power |
| Fix congestion near macros | Increase macro halo | More area |
| Fix pin-access DRCs | Increase cell padding | Higher effective density |
| Faster routing | Lower density | Larger die |
| Better timing | SS corner first → FF corner | — |
| Post-layout timing signoff | Run RCX preset (SPEF → STA → SDF) | Extra runtime |

Author: WilliamHHL
