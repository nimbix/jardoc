# Overview

JARVICE provides a complete environment to run MPI solvers with minimal setup.  This includes:

1. SSH trust established between nodes in a job, for the non-`root` user in the container (e.g. `nimbix`, but may be different based on platform identity policies for a given team/organization)
2. `/etc/JARVICE/nodes` and `/etc/JARVICE/cores` files generated automatically, which can be used as machine files for `mpirun` commands; the former contains a list of all nodes in a job, starting with the node that will run `mpirun` in the first position, one per line; the latter contains the same list, but with the hostnames repeated times the number of processes that should run on each node
3. Detection of CMA (Cross Memory Attach) capabilities
4. Detection of the appropriate provider to select for OFI fabric
5. Deployment of entire MPI stack including latest stable versions of Open MPI, `libfabric`, and `rdma-core` that can be used directly (see below)

## Determining the number of MPI processes to run

Applications calling `mpirun` may need to specify the number of processes to use.  These values can be passed in as `CONST` parameter values from AppDefs themselves (`%CORES%` and `%TCORES%` for the number of processes per node and the total number of processes across an entire job, respectively).  Alternatively they can be calculated from a script before passing to `mpirun` - e.g. (in Bash):

```bash
tcores=$(cat /etc/JARVICE/cores|wc -l)              # total cores for job
let cores=$tcores/$(cat /etc/JARVICE/nodes|wc -l)   # cores per node
```

**NOTE**: applications should not rely on CPU topology directly to determine how to configure MPI, as JARVICE users may specify fewer cores for a given job.  These core counts should only be determined as specified above when specifying the number of MPI processes to run.

## Parameterizing application-supplied MPI libraries

Some MPI libraries need specific parameterization and cannot reliably detect fabric configuration.  JARVICE provides guidance via environment variables that can be used as follows (example in Bash for parameterizing Intel MPI):

```bash
## assumes the shell variable ${impi_version} is set to the Intel MPI version;
## this must be determined in your script, or hardcoded depending on what the
## application package provides

[ -z "$JARVICE_MPI_PROVIDER" ] && JARVICE_MPI_PROVIDER=tcp || true
if [ $impi_version -lt 2019 ]; then
    if [ "$JARVICE_MPI_CMA" != "true" ]; then
        export I_MPI_SHM_LMT=shm
        I_MPI_FABRICS=""
    else
        I_MPI_FABRICS="shm:"     # will append later
    fi

    # without OFI, assume `dapl` for `verbs` provider or `tcp` for
    # for anything else
    [ "$JARVICE_MPI_PROVIDER" = "verbs" ] && \
        export I_MPI_FABRICS=${I_MPI_FABRICS}dapl || \
        export I_MPI_FABRICS=${I_MPI_FABRICS}tcp
else

    # use OFI, but shm is conditional on CMA
    [ "$JARVICE_MPI_CMA" != true ] && \
        export I_MPI_FABRICS=ofi || \
        export I_MPI_FABRICS=shm:ofi
    export I_MPI_OFI_PROVIDER=${JARVICE_MPI_PROVIDER}
fi
```

**IMPORTANT NOTE:** when using OFI, and `${JARVICE_MPI_PROVIDER}` is set (not empty), the best practice is to use the JARVICE-provided `libfabric` (which is configured properly with `ldconfig`); this to ensure that providers detected are properly supported.  If JARVICE does not set `${JARVICE_MPI_PROVIDER}`, it means that version of JARVICE does not provide a `libfabric`; note that this is provided only in versions of JARVICE newer than **3.21.9-1.202107070100**.  The above conditional logic example will allow "graceful degradation" to `tcp` fabric without CMA, which should be supported by the application-provided MPI's `libfabric`.

## Using JARVICE-provided Open MPI and OFI

JARVICE versions newer than **3.21.9-1.202107070100** provide the latest stable version of Open MPI, which applications can use without providing their own libraries.  This includes the entire stack, including `libfabric` and `rdma-core`.  Library paths are configured automatically with `ldconfig`, and the `${OPENMPI_DIR}` variable is set to point to the JARVICE-supplied version.  If this variable is not set, the specific version of JARVICE does not provide Open MPI.  The following conditional example can be used (Bash):

```bash
## assumes application provides its own mpirun in ${PATH}; if not, it should
## exit with an error if JARVICE does not set the variable, indicating the
## particular version of JARVICE is not supported
[ -n "$OPENMPI_DIR" ] && MPIRUN="$OPENMPI_DIR"/bin/mpirun || MPIRUN=mpirun
```

When using the JARVICE-provided Open MPI, no additional environment configuration is needed.  Note that certain applications may need to be specifically told to use the system `libfabric` rather than provide their own.  This is mandatory to ensure that the JARVICE-detected provider is indeed supported.

