# Backend Physical Design Guide

A practical introductory reference for RTL-to-GDS physical design.

This guide is based primarily on **ECC / OpenROAD-style flows**, but most concepts also apply to OpenLane and commercial ASIC flows.

> **Important:** Numerical values in this guide are illustrative starting points, not universal rules.  
> Actual settings depend strongly on the **PDK, standard-cell library, design size, macro configuration, routing stack, tool, and flow version**.

---

## 1. The Fundamental Relationship: Utilization, Density, and Area

### 1.1 Synthesis area and floorplan size

After synthesis, the design has a total physical cell area determined by the mapped standard cells and macros.

For a simple macro-free design:

```text
core_area ≈ total_cell_area / target_core_utilization
```

For example, if:

```text
total_cell_area = 250,000 µm²
core_util       = 0.70
```

then:

```text
core_area ≈ 250,000 / 0.70
          ≈ 357,143 µm²
```

For an approximately square core:

```text
core_side ≈ √core_area
          ≈ 598 µm
```

If the core-to-die margin is `m` on every side:

```text
die_side = core_side + 2m
die_area = (√core_area + 2m)²
```

Therefore:

```text
die_area = core_area
         + 4m√core_area
         + 4m²
```

Higher core utilization generally means:

```text
higher utilization
        ↓
smaller core
        ↓
shorter average wires / smaller area
        ↓
less routing whitespace
        ↓
higher congestion risk
```

So utilization is fundamentally an **area versus routability trade-off**.

---

### 1.2 Core utilization vs placement density

These two parameters are related, but they are not the same thing.

| Parameter | Stage | Main purpose |
|---|---|---|
| `core_utilization` | Floorplan | Determines the approximate core size |
| `placement_density` | Global placement | Controls how densely movable cells are packed |

A useful mental model is:

```text
core utilization → how large the playground is
placement density → how tightly the cells occupy that playground
```

The exact definition varies between tools and flows.

In OpenROAD-style flows, the placement density must be physically feasible for the available placement area. If the requested density is too low for the amount of movable-cell area, the placer may increase the effective density or report that the requested target is infeasible.

Therefore, avoid treating rules such as:

```text
density = utilization + 0.05
```

as universal formulas.

Instead:

1. Start with a reasonably loose floorplan.
2. Run placement.
3. Check congestion and placement quality.
4. Increase utilization/density gradually.
5. Find the point where routability begins to degrade rapidly.

---

### 1.3 Macros make utilization more complicated

With SRAMs, ROMs, analog macros, PLLs, or other fixed blocks, simple utilization calculations become less reliable.

Suppose:

```text
core area          = 1.00
macro area         = 0.17
total occupied     = 0.70
```

Then the standard-cell area is approximately:

```text
stdcell_area = 0.70 - 0.17
             = 0.53
```

The area remaining outside the macros is:

```text
available_stdcell_region = 1.00 - 0.17
                         = 0.83
```

Therefore the effective standard-cell utilization of the remaining region is:

```text
effective_stdcell_util = 0.53 / 0.83
                       ≈ 0.64
```

However, this still does **not** fully describe routability.

Macros can block:

- Placement sites
- Routing tracks
- Power stripes
- Signal access
- Clock routing
- Pin-access regions

Therefore, two designs with the same numerical utilization may have very different routing difficulty.

> With macros, always inspect the actual floorplan and congestion maps rather than relying only on one utilization number.

---

## 2. Macro Placement

Macro placement can strongly affect routability, timing, and DRC closure.

### 2.1 Pin accessibility

Whenever possible, orient macros so that heavily used signal pins face regions where connected standard cells and routing resources are available.

For example:

```text
+-----------------------------+
|                             |
|         Standard cells      |
|                             |
|     ↑ connected signals     |
|  +----------------------+   |
|  |        SRAM          |   |
|  | pins on upper edge   |   |
|  +----------------------+   |
|                             |
+-----------------------------+
```

Avoid placing heavily used macro pins directly against:

- Die boundaries
- Power rings
- Other macros
- Routing blockages

The correct orientation depends on the macro's actual pin locations.

---

### 2.2 Edge clearance

Do not place macros unnecessarily close to the core or die boundary.

You need enough space for:

- Signal routing
- Power routing
- Macro pin access
- CTS
- Routing detours

There is **no universal minimum such as 50 µm**.

The required clearance depends on:

- Technology node
- Routing pitch
- Macro pin density
- Power-grid structure
- Number of routing layers
- I/O architecture

Start conservatively and reduce the clearance only after verifying routability.

---

### 2.3 Macro alignment and centering

For symmetric designs, centering macros can sometimes give the placer more balanced routing space.

For example:

```text
macro_llx = core_width / 2 - macro_width / 2
```

But centering is not always optimal.

Macro placement should primarily follow:

1. Connectivity
2. Pin accessibility
3. Routing channels
4. Power delivery
5. Timing-critical paths

---

### 2.4 Routing channels between macros

Avoid tightly abutting macros when significant routing must pass between them.

Leave enough channel space for:

- Signal wires
- Power straps
- Clock routes
- Macro pin access

The required channel width is design- and PDK-dependent.

A larger channel improves routability but increases area.

---

### 2.5 Macro halo

A macro halo creates a keep-out region around a macro so standard cells are not placed directly against it.

Benefits include:

- Better macro pin accessibility
- Reduced local congestion
- More room for routing detours
- Fewer boundary DRC problems

Example:

```text
        halo
  <------------->
  +-------------+
  |             |
  |    MACRO    |
  |             |
  +-------------+
```

The halo value should be tuned for the design.

Typical starting values may be several micrometers in mature-node designs, but there is no universal number.

---

## 3. Floorplan Parameters

### 3.1 Aspect ratio

For a rectangular core:

```text
aspect_ratio = height / width
```

A value near `1.0` produces an approximately square floorplan.

Square floorplans often provide balanced routing distance, but non-square floorplans may be useful when:

- Macros are strongly rectangular
- I/O constraints require it
- Connectivity has a dominant direction
- Routing congestion is asymmetric

The best aspect ratio is the one that produces the best overall:

```text
area + timing + routability + power
```

---

### 3.2 Core margin

The core margin is the space between the standard-cell core boundary and the die boundary.

It may provide room for:

- Power rings
- I/O structures
- Routing
- Decoupling structures
- Boundary cells

For a square design:

```text
die_side = core_side + 2 × margin
```

The correct margin is strongly PDK- and flow-dependent.

Too small:

```text
→ peripheral congestion
→ PDN conflicts
→ difficult I/O routing
```

Too large:

```text
→ unnecessary die-area increase
```

---

### 3.3 A practical iteration strategy

For a new design, start conservatively.

For example:

```text
Run 1:
    core_util ≈ 0.45–0.55
    moderate placement density

Run 2:
    increase utilization slightly

Run 3:
    increase again

...

Stop when:
    congestion rises sharply
    routing runtime increases dramatically
    DRC closure becomes difficult
    timing degrades significantly
```

This identifies the approximate **routability knee**.

Then refine around that region using smaller parameter changes.

---

## 4. Placement

### 4.1 Cell padding

Placement padding reserves additional placement space around standard cells.

Conceptually:

```text
[cell][padding][cell][padding][cell]
```

Advantages:

- Better pin accessibility
- More routing whitespace
- Lower local routing congestion
- Sometimes fewer detailed-routing violations

Disadvantages:

- Lower effective placement capacity
- Higher effective utilization
- Potentially larger required core area

> **Important:** Padding units are tool-specific.

For example, OpenROAD placement padding is typically specified in **placement sites**, not nanometers.

Therefore, a value such as:

```text
padding = 4
```

may mean four placement sites rather than `4 nm` or `4 µm`.

Always check the documentation of the specific flow.

---

### 4.2 Routability-driven placement

Modern placers can use routing congestion estimates during global placement.

For routability-sensitive designs, enabling routability optimization can help move cells away from highly congested regions.

However:

```text
better routability
        ↔
potential timing / wirelength / density trade-offs
```

So it should be evaluated rather than blindly maximized.

---

### 4.3 Placement overflow vs routing congestion

These are **not the same metric**.

#### Placement overflow

Global placers such as OpenROAD's Nesterov placer use an overflow metric to measure how much the placement density exceeds the capacity of placement bins.

Conceptually:

```text
cell demand > placement-bin capacity
```

This is primarily a **placement convergence metric**.

#### Routing congestion

Routing congestion compares routing demand against available routing resources.

Conceptually:

```text
routing demand / routing capacity
```

A region where routing demand exceeds available tracks is congested.

Tools may visualize this using:

- Global-routing congestion maps
- RUDY estimates
- Pin-density maps
- Routing overflow reports

Therefore:

> **Placement overflow ≠ routing overflow/congestion.**

They are related, but they describe different physical resources.

---

### 4.4 Congestion maps

Useful maps include:

#### RUDY

RUDY estimates routing demand from net bounding boxes.

Hotspots suggest regions where many nets compete for routing resources.

#### Pin density

A high concentration of pins can cause difficult detailed routing even when cell utilization is moderate.

#### Global-routing congestion

After global routing, demand/capacity maps provide a more realistic indication of routing difficulty.

If severe hotspots appear, common fixes include:

```text
increase core area
lower placement density
add padding selectively
move macros
increase macro halo/channel
improve RTL structure
reduce high-fanout nets
adjust routing resources
```

---

## 5. Clock Tree Synthesis (CTS)

### 5.1 What CTS does

Before CTS, the clock is usually treated approximately as an ideal or estimated network.

CTS constructs a physical clock-distribution network using:

- Clock buffers
- Clock inverters
- Routing
- Branching structures

Its objective is to distribute the clock to all sequential sinks while controlling:

- Clock skew
- Clock latency
- Slew
- Power
- Routing congestion

---

### 5.2 Important CTS metrics

#### Clock skew

Difference in clock arrival time between clock sinks.

Lower skew is generally desirable, but the acceptable target depends on:

- Clock period
- Technology
- Design size
- Clock architecture

A fixed number such as `100 ps` should not be treated as universal.

#### Clock latency

Time required for the clock to propagate from the clock source to a sink.

#### Buffer count

Large clock trees may require many buffers.

More buffers generally mean:

```text
more clock power
more area
more routing
```

but too few buffers may produce poor slew and timing.

---

### 5.3 If CTS inserts no clock buffers

If the design contains many sequential elements but CTS inserts zero buffers, check:

- Is the clock correctly defined in the SDC?
- Does the clock port name match the RTL/netlist?
- Is the clock propagated to the sequential cells?
- Has synthesis accidentally optimized the clock structure?
- Is CTS actually enabled for this clock?

---

### 5.4 CTS and timing

Do **not** think of CTS as:

```text
more clock delay → setup worse → hold better
```

Clock insertion delay common to both launch and capture registers largely cancels out.

What matters strongly is the **relative clock arrival time**, or clock skew.

Consider:

```text
launch FF ---> combinational logic ---> capture FF
```

If the capture clock arrives later than the launch clock:

```text
positive skew
```

then approximately:

```text
setup becomes easier
hold becomes harder
```

If the capture clock arrives earlier:

```text
negative skew
```

then approximately:

```text
setup becomes harder
hold becomes easier
```

Real STA additionally considers:

- Clock uncertainty
- Different clock paths
- Jitter
- OCV
- CRPR
- Library setup/hold times

This is why post-CTS STA is essential.

---

## 6. Routing

Routing is usually divided into:

```text
Global Routing
      ↓
Detailed Routing
```

### 6.1 Global routing

Global routing determines approximate routing paths and estimates routing demand.

It is useful for identifying:

- Congestion hotspots
- Long nets
- Routing bottlenecks
- Layer demand

---

### 6.2 Detailed routing

Detailed routing assigns exact:

- Tracks
- Wire shapes
- Vias

while satisfying technology DRC rules.

Detailed routers repeatedly perform operations similar to:

```text
route
↓
detect violations
↓
rip-up problematic routes
↓
reroute
↓
repeat
```

As congestion becomes severe, routing runtime can increase **nonlinearly**.

Do not rely on universal rules such as:

```text
1000 DRCs = 5 minutes
10000 DRCs = 20 minutes
```

Runtime depends heavily on:

- Design size
- CPU/thread count
- PDK
- Routing stack
- Router
- Violation type
- Congestion distribution

---

### 6.3 Routing-layer stack

Metal-layer usage is PDK-specific.

A technology may have:

```text
M1
M2
M3
M4
M5
...
```

but the preferred direction and intended use of each layer can differ between technologies.

For example, some processes alternate:

```text
horizontal
vertical
horizontal
vertical
...
```

while power-grid and RDL usage may reserve some layers.

Therefore, do not assume universally that:

```text
M2 = horizontal
M3 = vertical
M6 = RDL
```

Always check the technology LEF and flow configuration.

---

### 6.4 Common routing violations

Typical detailed-routing violations include:

| Type | General meaning |
|---|---|
| Metal spacing | Two metal shapes are too close |
| Short | Different nets electrically overlap |
| Via/cut spacing | Vias are too close |
| Minimum area | Metal geometry is smaller than allowed |
| Minimum width | Wire is too narrow |
| Enclosure | Via enclosure is insufficient |
| End-of-line spacing | Wire-end spacing rule violation |
| Parallel-run-length | Long parallel wires require additional spacing |

The exact names depend on the PDK and DRC engine.

---

### 6.5 Final DRC target

During routing optimization, intermediate violation counts may be non-zero.

However:

> **The final signoff target is DRC = 0.**

A design with hundreds or thousands of unresolved routing violations is not considered physically clean simply because the router completed.

---

## 7. Static Timing Analysis (STA)

### 7.1 Timing corners

Digital libraries are characterized under different:

- Process
- Voltage
- Temperature

conditions.

Common conceptual corners include:

```text
SS = slow NMOS + slow PMOS
TT = typical
FF = fast NMOS + fast PMOS
```

A traditional simplified view is:

```text
slow / low-voltage / hot
    → often important for setup

fast / high-voltage / cold
    → often important for hold
```

However, modern signoff uses multiple PVT and RC corners.

Do not assume one SS corner and one FF corner are sufficient for every technology.

---

### 7.2 Setup timing

Setup checks whether data arrives early enough before the capture clock edge.

Simplified:

```text
data arrival time
    <
required setup time
```

Slack:

```text
setup_slack = required_time - arrival_time
```

Interpretation:

```text
slack > 0  → timing met
slack = 0  → exactly at the constraint
slack < 0  → timing violation
```

---

### 7.3 Fixing setup violations

Setup violations mean the maximum-delay path is too slow.

Common approaches:

1. Reduce logic depth
2. Improve RTL architecture
3. Upsize critical-path cells
4. Use faster-VT cells where appropriate
5. Reduce fanout
6. Improve placement
7. Reduce wirelength
8. Buffer long/high-fanout nets
9. Use useful clock skew when supported
10. Relax the clock period if necessary

Trade-offs may include:

```text
faster cells → larger area / higher power
more buffers → more area / power
larger die → longer wires
higher density → worse routing
```

Timing optimization is therefore a multi-objective problem.

---

### 7.4 Hold timing

Hold checks whether data remains stable long enough after the capture clock edge.

A hold violation means the minimum-delay data path is too fast relative to the clocks.

Common fixes include:

1. Insert dedicated delay/buffer cells
2. Increase minimum data-path delay
3. Use slower cells where appropriate
4. Modify routing to add delay
5. Apply useful skew in the correct direction

Do **not** assume that simply upsizing cells fixes hold.

Upsizing often makes cells faster and can make a hold problem worse.

---

### 7.5 Clock uncertainty

Clock uncertainty represents timing margin associated with effects such as:

- Clock jitter
- Modeling uncertainty
- Residual skew
- Variation margin

The correct value depends on the clock architecture and signoff methodology.

Do not assume a universal value such as:

```text
200–300 ps
```

for every 100 MHz design.

A 100 MHz clock has a period of:

```text
10 ns
```

but uncertainty should still be based on the actual clock source and design methodology rather than frequency alone.

---

## 8. Power Delivery Network (PDN)

### 8.1 Purpose

The power-delivery network distributes:

```text
VDD
VSS / GND
```

throughout the chip.

Poor PDN design can cause:

```text
IR drop
      ↓
lower local supply voltage
      ↓
slower cells
      ↓
timing degradation
```

It can also cause electromigration reliability problems.

---

### 8.2 Typical PDN hierarchy

A PDN may include:

```text
package / bumps / pads
        ↓
power ring
        ↓
power stripes
        ↓
local rails
        ↓
standard-cell power pins
```

Different metal layers are typically used for different levels of the hierarchy.

The exact layers and dimensions are PDK-specific.

---

### 8.3 What to check

Check that:

- All required power domains are connected
- Standard-cell rails connect correctly
- Macro power pins connect correctly
- No large unpowered regions exist
- Stripe pitch and width are reasonable
- Via connectivity is complete
- IR drop is acceptable
- Current density does not violate EM limits

A stripe pitch that works for one 55 nm library may not be appropriate for another design.

---

## 9. Tap Cells, Filler Cells, Decap Cells, and Metal Fill

These are related but **not the same thing**.

### 9.1 Tap cells

Tap cells connect semiconductor wells/substrate to the power network.

Conceptually:

```text
N-well → VDD
P-substrate / P-well → VSS
```

They must generally be inserted according to maximum-spacing rules defined by the technology/library.

In OpenROAD-style flows, tap-cell insertion is usually a separate step.

---

### 9.2 Filler cells

After placement, gaps may remain between standard cells.

Filler cells fill legal row gaps and help maintain:

- Well continuity
- Power-rail continuity
- Proper standard-cell-row structure

They normally contain no functional logic.

---

### 9.3 Decap cells

Decap cells contain intentional capacitance between the power rails.

Their purpose is to help reduce local supply-voltage fluctuations.

Therefore:

```text
ordinary filler ≠ decap filler
```

Some flows use decap cells to fill available whitespace, but not every filler is a decap.

---

### 9.4 Metal fill

Metal density rules are usually handled separately using **metal fill**.

Metal fill inserts non-functional metal shapes so the design satisfies manufacturing density requirements.

Therefore:

```text
standard-cell filler
        ≠
metal-density fill
```

Do not assume that filler-cell insertion automatically satisfies metal-density rules.

---

## 10. RC Extraction and Post-Route STA

### 10.1 Why parasitic extraction matters

After placement and routing, physical wires introduce:

- Resistance
- Capacitance
- Coupling effects

These parasitics significantly affect timing.

A common extracted-parasitic format is:

```text
SPEF
```

---

### 10.2 Pre-route vs post-route timing

Before routing, wire delay is based on estimates.

After routing and RC extraction:

```text
actual geometry
      ↓
extracted RC
      ↓
more accurate STA
```

It is common for paths that looked safe before routing to become worse after detailed routing.

For routing-heavy designs, interconnect delay may dominate the critical path.

---

### 10.3 Post-route STA

A typical post-route STA setup uses:

```text
post-route netlist
+
Liberty timing libraries
+
SDC constraints
+
extracted parasitics (for example SPEF)
```

Then run setup and hold analysis across the required signoff corners.

---

### 10.4 SDF

SDF stands for:

```text
Standard Delay Format
```

It can contain back-annotated timing delays for simulation.

A common use is:

```text
gate-level netlist
+
SDF
+
testbench
=
timing-aware gate-level simulation
```

SDF is **not required just to perform post-route STA**.

Typical STA uses timing libraries, constraints, and extracted parasitics directly.

---

## 11. A Practical Iteration Workflow

A useful exploration strategy for a new design is:

```text
Run 1:
    conservative core utilization
    conservative placement density
    little or no padding

    ↓

Check:
    placement
    congestion
    timing
    routing
    DRC

    ↓

Run 2:
    slightly increase utilization

    ↓

Run 3:
    slightly increase again

    ↓

Continue until:
    routing congestion rises sharply
    timing degrades
    DRC closure becomes difficult
    routing runtime increases strongly
```

Then back off slightly and refine around the best region.

For example:

```text
0.50
0.55
0.60
0.65
0.70
```

may be a reasonable exploratory sweep for one design.

But it does **not** mean that `0.70` is inherently good or bad.

A design may route cleanly at:

```text
80%+
```

while another may struggle below:

```text
60%
```

depending on:

- Number of cells
- Pin density
- Fanout
- Macro placement
- Routing-layer availability
- Netlist topology
- Clock structure
- Power grid
- Technology node

---

## 12. Why Small Designs Can Often Reach Higher Utilization

A small design may sometimes tolerate much higher utilization than a large design.

This is because routing difficulty does not scale only with area.

Large designs typically contain:

- More nets
- More long-distance connections
- More high-fanout signals
- Larger clock trees
- More routing interactions
- More congestion hotspots

For a small design:

```text
cells can be densely packed
while most connections remain short
```

For a large design:

```text
high utilization
        +
many long nets
        +
high pin density
        ↓
routing congestion grows rapidly
```

Therefore:

> Maximum achievable utilization is a property of the **design and technology**, not a universal percentage.

---

## 13. RTL Can Dominate Backend Difficulty

Physical-design problems are not always solvable by changing backend parameters.

For example, RTL can create:

- Large mux trees
- High-fanout control signals
- Large comparators
- Wide priority logic
- Large register arrays
- Very long combinational paths

These may create:

```text
poor timing
+
many inserted buffers
+
large routing demand
+
high congestion
```

In those cases, changing:

```text
utilization
density
padding
```

may only partially help.

The real solution may require RTL changes.

Examples:

```text
pipeline the logic
reduce fanout
duplicate control logic
restructure muxes
bank large arrays
reduce comparator width
change the microarchitecture
```

A successful backend flow therefore requires feedback between:

```text
RTL
↕
Synthesis
↕
Physical Design
```

---

## 14. Understanding High-Fanout Nets

A signal driving many loads may require a large buffer tree.

For example:

```text
control_signal
      |
      +----> load
      +----> load
      +----> load
      +----> ...
      +----> hundreds of loads
```

Synthesis or physical optimization may transform this into:

```text
              buffer
             /      \
         buffer    buffer
        /    \      /   \
      ...   ...   ...   ...
```

This improves electrical slew and timing but increases:

- Cell count
- Area
- Dynamic power
- Routing demand

If a design unexpectedly contains dozens of buffer stages or hundreds of inserted buffers, inspect the original RTL driver and fanout structure.

---

## 15. Understanding Timing Reports

A critical path should be separated conceptually into:

```text
clock-to-Q
+
cell delay
+
interconnect delay
+
setup requirement
```

For example:

```text
Critical path = 9.8 ns

Clock-to-Q        0.2 ns
Logic delay       3.5 ns
Wire delay        5.5 ns
Other             0.6 ns
```

In this case:

```text
wire delay ≈ 56%
```

The design may be **interconnect dominated**.

Possible solutions include:

- Better placement
- Shorter physical distances
- Logic restructuring
- Fanout reduction
- Buffer insertion
- Pipeline restructuring

Simply optimizing gate count may not solve the problem.

---

## 16. Area, Timing, and Routability Form a Three-Way Trade-Off

Backend optimization is rarely about one metric.

Increasing utilization:

```text
smaller area
    +
potentially shorter wires
    -
less routing space
```

Adding padding:

```text
better pin access
    +
better routability
    -
less placement capacity
```

Upsizing cells:

```text
better timing
    -
more area
    -
more power
    -
sometimes more congestion
```

Increasing core area:

```text
better routability
    +
more whitespace
    -
larger die
    -
possibly longer wires
```

Therefore, backend optimization is fundamentally a **multi-objective optimization problem**.

---

## 17. Quick Reference

| Goal | Possible action | Possible downside |
|---|---|---|
| Reduce area | Increase core utilization | More congestion |
| Reduce congestion | Increase core area | Larger die |
| Improve pin access | Add placement padding | Less placement capacity |
| Improve macro routing | Increase halo/channel | Larger floorplan |
| Fix setup | Faster cells / better placement / RTL optimization | Area/power |
| Fix hold | Add minimum-path delay | Area |
| Reduce high fanout | Buffer/duplicate/restructure logic | Area/power |
| Reduce routing runtime | Reduce congestion | May require larger area |
| Improve timing accuracy | Run post-route RC extraction + STA | More runtime |
| Validate physical correctness | Run final DRC | Must reach clean signoff |
| Validate layout connectivity | Run LVS | Additional signoff step |

---

## 18. A Simplified RTL-to-GDS Flow

A typical digital ASIC flow looks roughly like:

```text
RTL
 │
 ▼
Synthesis
 │
 ▼
Floorplan
 │
 ▼
PDN
 │
 ▼
Macro Placement
 │
 ▼
Global Placement
 │
 ▼
Detailed Placement
 │
 ▼
CTS
 │
 ▼
Post-CTS Optimization
 │
 ▼
Global Routing
 │
 ▼
Detailed Routing
 │
 ▼
Filler / Finishing
 │
 ▼
RC Extraction
 │
 ▼
Post-Route STA
 │
 ▼
DRC / LVS / Signoff
 │
 ▼
GDS
```

The exact sequence varies between flows.

---

## 19. What a Beginner Should Monitor

Instead of staring only at whether the flow finishes, monitor metrics after every major stage.

### After synthesis

Check:

```text
cell area
cell count
critical path
high-fanout nets
large combinational structures
```

### After floorplan

Check:

```text
core utilization
macro placement
macro channels
PDN space
pin accessibility
```

### After placement

Check:

```text
placement density
congestion
wirelength
timing
high-fanout buffering
```

### After CTS

Check:

```text
clock skew
clock latency
clock slew
clock-buffer count
setup timing
hold timing
```

### After routing

Check:

```text
DRC violations
routing congestion
wirelength
via count
timing
```

### After RC extraction

Check:

```text
setup slack
hold slack
critical-path composition
wire-delay contribution
```

### Before tapeout

At minimum, ensure the required signoff checks are clean according to the project methodology, including:

```text
DRC
LVS
STA
power integrity / IR drop where required
```

---

## 20. Final Advice

Do not optimize backend parameters blindly.

A useful engineering loop is:

```text
Run
 ↓
Measure
 ↓
Understand the bottleneck
 ↓
Change one meaningful parameter
 ↓
Run again
```

Do not assume:

```text
higher utilization = always better
lower density = always better
more padding = always better
fewer cells = always faster
clean placement = clean routing
pre-route timing = final timing
```

Instead, understand **why** a design fails.

The backend flow is ultimately trying to satisfy several competing objectives:

```text
Timing
Area
Power
Routability
Signal Integrity
Power Integrity
Manufacturing Rules
```

The best configuration is not the most aggressive one.

It is the configuration that reaches **signoff cleanly while meeting the design targets**.

---

## Disclaimer

This document is intended as an introductory engineering guide.

Values such as:

```text
utilization
density
padding
macro halo
routing channel width
clock uncertainty
PDN stripe pitch
routing-layer selection
```

are **technology-, library-, design-, and tool-dependent**.

Always verify numerical settings against:

- Your PDK documentation
- Standard-cell library documentation
- Tool documentation
- Reference flow configuration
- Actual congestion, timing, and DRC results

---

Author: WilliamHHL
