# Procesador RISC-V single-cycle en SystemVerilog

Parcial 4 – Arquitectura de Computadoras, UNIS.
Autor: José Rueda (carné 18123).

Procesador RISC-V de **un solo ciclo** (single-cycle) descrito en SystemVerilog, basado en el capítulo 7 de *Digital Design and Computer Architecture* (Harris & Harris) y en el repositorio de referencia indicado en el curso. Cada instrucción se completa en un ciclo de reloj: fetch, decode, execute, memory y write-back.

Video explicativo: [enlace pendiente]

![Jerarquía y camino de datos](diagrama_jerarquia_y_datapath.png)

## Instrucciones soportadas

Se implementó el subconjunto del video, más `addi` y `jal`, que el mismo video presenta como las siguientes en agregarse.

| Tipo | Instrucciones |
|---|---|
| Aritmético-lógicas (R) | `add`, `sub`, `and`, `or`, `slt` |
| Con inmediato (I) | `addi` |
| Memoria | `lw`, `sw` |
| Saltos condicionales (B) | `beq` |
| Salto incondicional (J) | `jal` |

Una instrucción no soportada se ejecuta como si fuera un NOP: no escribe registros ni memoria.

## Archivos

| Archivo | Descripción |
|---|---|
| `riscv_top.sv` | **TOP**. Conecta todos los bloques. Puertos: `clk`, `rst`, y salidas de observación `pc`, `instr`, `result`. Parámetro `DMEM_WORDS` (por defecto 16) |
| `pc_reg.sv` | Contador de programa, reset síncrono |
| `imem.sv` | Memoria de instrucciones (ROM combinacional con el programa de prueba) |
| `control_unit.sv` | Decodificador principal y decodificador de la ALU |
| `imm_gen.sv` | Generador de inmediatos (tipos I, S, B y J) |
| `regfile.sv` | Banco de 32 registros de 32 bits, 2 lecturas combinacionales y 1 escritura síncrona; `x0` siempre vale 0 |
| `alu.sv` | ALU: suma, resta, AND, OR y SLT con signo |
| `dmem.sv` | Memoria de datos (lectura combinacional, escritura síncrona) |
| `tb_riscv_top.sv` | Testbench autoverificable |
| `expected.svh` | Valores esperados (registros y memoria) generados por el simulador de referencia |
| `gen_program.py` | Mini ensamblador RV32I + simulador de referencia en Python; genera `imem.sv`, `expected.svh` y `program.hex` |
| `program.hex` | Programa de prueba en hexadecimal |
| `files.f` | Lista de archivos para VCS |
| `resultado_simulacion_*.log` | Salida de las simulaciones |

## Programa de prueba

El programa (41 instrucciones, 73 ciclos hasta su bucle final) ejercita todas las instrucciones:

- Operaciones aritmético-lógicas con valores positivos y negativos (`add`, `sub`, `and`, `or`, `slt` con signo).
- `sw` y `lw` con comprobación de lo leído.
- `beq` tomados y no tomados (cuatro en el código, uno de ellos dentro del bucle).
- `jal` con enlace.
- Un bucle que suma 10 + 9 + ... + 1 y guarda **55** en la memoria de datos.

## Cómo verificarlo

El testbench ejecuta el programa hasta el bucle final y compara **todos los registros escritos y la memoria de datos** contra los valores que calcula el simulador de referencia en Python (`gen_program.py`), que es independiente del RTL. Termina con la línea `Errores: N`.

### Icarus Verilog

```sh
iverilog -g2012 -o sim.vvp -s tb_riscv_top pc_reg.sv regfile.sv imm_gen.sv alu.sv control_unit.sv dmem.sv imem.sv riscv_top.sv tb_riscv_top.sv
vvp sim.vvp
```

### Synopsys VCS / Verdi

```sh
vcs -full64 -sverilog -kdb -debug_access+all -f files.f -o simv
./simv -no_save
verdi -dbdir simv.daidir -ssf dump_riscv.fsdb &
```

### AMD Vivado

Se creó un proyecto RTL para el Artix-7 `xc7a35tcpg236-1`. Archivos de diseño: los 8 `.sv` del procesador (`riscv_top` como top). Archivos de simulación: `tb_riscv_top.sv` y `expected.svh`. Restricción de reloj en `riscv.xdc`:

```
create_clock -period 12.000 -name clk [get_ports clk]
```

## Resultados

### Verificación funcional

| Herramienta | Resultado |
|---|---|
| Icarus Verilog 12 | `Errores: 0` (73 ciclos, 776 ns) |
| Synopsys VCS X-2025.06-SP2-6 | `Errores: 0` (73 ciclos, 776 ns) |
| Vivado Simulator 2025.1 | `Errores: 0` (73 ciclos, 776 ns) |

Para comprobar que el testbench detecta fallas, se introdujeron 7 errores a propósito en el diseño (`sub` implementado como suma, `slt` sin signo, `beq` invertido, `jal` que guarda el PC equivocado, inmediato de `sw` mal armado, `or` implementado como `and` y `lw` que devuelve la salida de la ALU). El testbench detectó los 7.

### Evidencia de VCS y Verdi

Primeras instrucciones: `pc` avanza de 4 en 4, `instr` muestra cada instrucción y `result` el dato que se escribe (10, 5, 15, 5, 0, 15, 1, 0, -3, ...).

![Verdi: primeras instrucciones](evidencia/01_verdi_primeras_instrucciones.png)

Programa completo (0 a 776 ns): `ciclos` llega a 73, `errores` se mantiene en 0 y `pc` termina en `a0`, el bucle final.

![Verdi: programa completo](evidencia/02_verdi_programa_completo.png)

### Vivado: simulación

![Vivado: simulación](evidencia/vivado_simulacion.png)

### Vivado: síntesis e implementación (xc7a35tcpg236-1)

| Recurso | Usado | Disponible | % |
|---|---|---|---|
| LUT | 498 | 20,800 | 2.39 |
| LUTRAM | 80 | 9,600 | 0.83 |
| FF | 32 | 41,600 | 0.08 |
| IO | 98 | 106 | 92.45 |
| BUFG | 1 | 32 | 3.13 |

Los 32 flip-flops son los del contador de programa. Vivado implementó el banco de registros y la memoria de datos como memoria distribuida (LUTRAM), por eso casi no usa FF. El IO es alto porque el módulo expone `pc`, `instr` y `result` (32 bits cada uno) además de `clk` y `rst`.

![Vivado: utilización tras la síntesis](evidencia/vivado_sintesis_utilizacion.png)

![Vivado: utilización tras la implementación](evidencia/vivado_impl_utilizacion.png)

![Vivado: diseño colocado en la FPGA](evidencia/vivado_impl_device.png)

### Vivado: timing

| Periodo de reloj | Frecuencia | WNS (setup) | WHS (hold) | Resultado |
|---|---|---|---|---|
| 10 ns | 100 MHz | -0.907 ns | +0.277 ns | no cumple (84 caminos) |
| 12 ns | 83.3 MHz | **+0.331 ns** | +0.277 ns | cumple |

En un procesador single-cycle el periodo del reloj lo fija el camino más largo: leer la instrucción, leer registros, ALU, memoria de datos y escritura de vuelta. A 100 MHz ese camino no cabe (le faltan 0.907 ns); con 12 ns sí.

![Vivado: timing a 100 MHz](evidencia/vivado_timing_100MHz.png)

![Vivado: timing a 83 MHz](evidencia/vivado_timing_83MHz.png)

## Parte 2: diseño físico en Synopsys

Pendiente: síntesis y diseño físico con el PDK de GlobalFoundries y las librerías estándar de M31.

## Limitaciones

- Subconjunto de RV32I: 10 instrucciones en total. No hay accesos a byte ni media palabra, ni CSR ni excepciones.
- La memoria de instrucciones es una ROM con un programa fijo, generada por `gen_program.py`. Para otro programa hay que regenerarla.
- La memoria de datos es de 16 palabras por defecto y no tiene control de alineación.
- Los puertos `pc`, `instr` y `result` existen solo para observar el procesador; por eso el diseño usa muchos pines de la FPGA.
