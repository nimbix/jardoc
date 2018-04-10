# Overview
JARVICE allows resources to be specified as machine types, using a standardized nomenclature.  The basic machine type nomenclature is as follows:

*system-architecture[accelerator(s)]step*

These values are all service provider dependent.

## System Architectures

In the Nimbix Cloud the following architectures are supported:

- ```n``` - x86
- ```np8``` - IBM POWER8
- ```np9``` - IBM POWER9

## Complete Machine Type Examples

Machine Type|System Architecture|Accelerator(s)|Step
---|---|---|---
```n3```|x86_64|*none*|3
```ng4```|x86_64|GPU|4
```ngd5```|x86_64|Dual GPU|5
```np8g1```|POWER8|GPU|1
```np8g4```|POWER8|GPU|4
```np8gk4```|POWER8|GPU (K80)|4
```np8c1```|POWER8|*none*|1

- step details relating to accelerators, memory, and CPU cores are defined by the service provider
- for historical reasons the IBM POWER architecture defines GPU count as steps rather than accelerator type; accelerator type may include model code (e.g. "k" for K80) in this system architecture
- for historical reasons the "c" refers to CPU-only when it comes to accelerators on the IBM POWER architecture; on the x86 architecture "c" is implicit if no other accelerator is defined
- JARVICE will provide users with machine selections based on wildcards as well; the best practice is to use as much wildcard substitution as possible and allow the user to select the machine they want to run on, rather than specify machines very narrowly in AppDefs

## Best Practices for AppDefs Using Wildcards

- CPU only (x86): ```n[0-9]*```
- CPU only (POWER8 or POWER9): ```np*c*```
- Any (architecture depends on application): ```n*```
- GPU (x86): ```ng*```
- Xilinx FPGA (x86): ```nx*``` *
- Xilinx FPGA (CAPI on IBM POWER): ```np[89]f*``` *

\* FPGA selection should be more explicit in order to ensure compatibility with your bitstream.

Please see [The JARVICE API: /jarvice/machines](api.md#jarvicemachines) for information on querying machine types from JARVICE.

