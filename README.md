# VIPS, MIPS32 based single-cycle model in Veryl-lang

> [!NOTE]
> This repo provides a synthesis workflow for the original Vips. In the process, i've broken the tests, so disregard those for now.
## Dependencies

- Verilator, [install](https://verilator.org/guide/latest/install.html)
- Veryl, [install](https://veryl-lang.org/install/)
- Optional dependencies:
  - Surfer, [install](https://gitlab.com/surfer-project/surfer) (Stand alone wave viewer)
  - Marlin, [library](https://www.ethanuppal.com/marlin/) (used as a Rust library)
  - Cocotb, [install](https://docs.cocotb.org/en/stable/install.html)

## Installation

The project has been tested under Linux (arch, and arch based Manjaro) and MacOs.

Rust based tooling (Veryl, Surfer) works as expected cross the board of operating systems. (First make sure that you have a work rust tool-chain installed ([Rust](https://www.rust-lang.org/tools/install)), and follow the instructions for installing Veryl and Surfer as above). Marlin is brought in as a library by Veryl, so no separate installation is required.

For Verilator, you may use your system's package manager. Under arch based Linux `pacman`, while under MacOs either [Brew](https://brew.sh/) or [Mac Ports](https://www.macports.org/). For better performance you may want to install Verilator from source. This allows to use `ccache`for accelerating incremental builds and `mold`for improved linker performance. Further details are operating system dependent and not covered here.

Cocotb, is implemented in python. Here you have the option to either install in the python package manager, or through the system wide package manager, so it depends on your system installation which way to go, python provides a jungle of opportunities to get lost.

The tests in this repo, exemplifies the various methods to test Veryl modules adopting System Verilog, cocotb and Marlin.

## Veryl Test, Simulation, and View

To test all modules:

```shell
veryl test --wave
surfer src/<module.vcd>
```

One can also test individual modules and their dependencies:
E.g., the `PcPlus4` module (which depends on `adder`, which depends on `full_adder`):

```shell
veryl test src/pc_plus4.veryl src/adder.veryl src/full_adder.veryl --wave
surfer src/pcplus4.vcd
```

Once this work, Drag `TOP/test` to the view pane, and you should get:

![image](images/pc_plus4.png)

## Marlin Test

This allows us to use the Rust built in test framework. The module under test is represented by a struct which fields correspond to the module "interface".

```sv
// src/alu32.veryl
module Alu32 (
    a  : input  logic<32>,
    b  : input  logic<32>,
    sub: input  logic    ,
    op : input  logic<2> ,
    r  : output logic<32>,
    v  : output logic    ,
    c  : output logic    ,
    z  : output logic    ,
)
```

```rust
// tests/veryl_tests.rs
...
#[veryl(src = "src/alu32.veryl", name = "Alu32")]
pub struct Alu;

#[test]
#[snafu::report]
fn test_alu() -> Result<(), Whatever> {
    ...

    let runtime = VerylRuntime::new(VerylRuntimeOptions {
        call_veryl_build: env::var("RUNNING_TESTS_INDEPENDENTLY")
            .map(|value| &value == "1")
            .unwrap_or(false),
        ..Default::default()
    })?;

    let mut alu = runtime.create_model::<Alu32>()?;

    alu.a = 0;
    alu.b = 0;
    alu.sub = 0;
    alu.op = 0;

    alu.eval();
    assert_eq!(alu.r,0); 
    ...
```

To run tests and capture the output:

```shell
veryl build
cargo test -- --nocapture
```

You can also run the test directly from within vscode by pressing the `Run Test` button.

## Vips registers

| Number |  Name  |
| :----: | :----: |
|   0    |  zero  |
|   1    |   at   |
|  2..3  | v0..v1 |
|  4..7  | a0..a2 |
| 8..15  | t0..t7 |
| 16..23 | s0..s7 |
| 24..25 | t8..t9 |
| 26..27 | k0..k1 |
|   28   |   gp   |
|   29   |   sp   |
|   30   |   fp   |
|   31   |   ra   |

## Modules

### Alu

The Alu module, configured for 4 bit wide inputs:

![image](images/vips_alu.svg)

The Alu has the `sub` and `op` inputs defined as follows:

| Operation | `sub` | `op`  |
| --------- | :---: | :---: |
| and       |   0   |  00   |
| or        |   0   |  01   |
| add       |   0   |  10   |
| sub       |   1   |  10   |
| slt       |   1   |  11   |

### Decoder

The VIPS support a subset of the MIPS32 ISA:

| Operation | `rf_we` | `wb_reg` | `sub` | `op`  | `alu_src` | `sign_ext` |
| --------- | :-----: | :------: | :---: | :---: | :-------: | :--------: |
| and       |    1    |    1     |   0   |  00   |     0     |     x      |
| or        |    1    |    1     |   0   |  01   |     0     |     x      |
| add       |    1    |    1     |   0   |  10   |     0     |     x      |
| sub       |    1    |    1     |   1   |  10   |     0     |     x      |
| slt       |    1    |    1     |   1   |  11   |     0     |     x      |
| andi      |    1    |    0     |   0   |  00   |     1     |     0      |
| ori       |    1    |    0     |   0   |  01   |     1     |     0      |
| addi      |    1    |    0     |   0   |  10   |     1     |     1      |
| slti      |    1    |    0     |   1   |  11   |     1     |     1      |

![image](images/decoder.svg)

## Simple Vips

![image](images/vips.svg)

## Full Vips

![image](images/vips_full.svg)


## List of current tests

For now using the explicit syntax for declaring dependencies.

```shell
# simple components
veryl test src/mux2.veryl --wave
veryl test src/mux4.veryl --wave
veryl test src/half_adder.veryl --wave
veryl test src/decoder1.veryl --wave
veryl test src/decoder.veryl --wave
veryl test src/zero_extend.veryl --wave
veryl test src/extend16to32.veryl --wave
veryl test src/regfile.veryl --wave 
veryl test src/data_memory.veryl --wave 
# composite components, alu 
veryl test src/pc_plus4.veryl src/adder.veryl src/full_adder.veryl --wave
veryl test src/arith_test.veryl src/arith.veryl src/full_adder.veryl --wave
veryl test src/alu.veryl src/mux4.veryl src/zero_extend.veryl src/arith.veryl src/full_adder.veryl --wave
veryl test src/alu4.veryl src/alu.veryl src/mux4.veryl src/zero_extend.veryl src/arith.veryl src/full_adder.veryl --wave
veryl test src/alu32.veryl src/alu.veryl src/mux4.veryl src/zero_extend.veryl src/arith.veryl src/full_adder.veryl --wave
# top level Vips1
veryl test src/alu.veryl src/vips1.veryl src/mux2.veryl src/extend16to32.veryl src/regfile.veryl src/decoder1.veryl src/instr_mem.veryl src/pc_plus4.veryl src/adder.veryl src/full_adder.veryl src/mux4.veryl src/zero_extend.veryl src/arith.veryl --wave
# top level Vips
veryl test src/alu.veryl src/vips.veryl src/mux2.veryl src/extend16to32.veryl src/regfile.veryl src/decoder.veryl src/instr_mem.veryl src/pc_plus4.veryl src/adder.veryl src/full_adder.veryl src/mux4.veryl src/zero_extend.veryl src/arith.veryl --wave

```


