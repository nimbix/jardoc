# Quick Start for Xilinx® SDAccel on JARVICE

This quick start guide will aid in developing and running an SDAccel® application for Xilinx FPGAs on JARVICE. Using the `SDAccel Development` and `SDAccel Runtime` applications on the [JARVICE Material Compute](https://platform.jarvice.com) portal, an [OpenCL](https://www.khronos.org/opencl/) application can be compiled and run on the [Nimbix Cloud](https://www.nimbix.net).

**Requirements** 

* JARVICE Material Compute credentials
* OpenCL source code for the application
* Target Xilinx FPGA

## Upload source files to JARVICE shared data store
 
 To build the SDAccel application, you can upload your OpenCL source files to JARVICE. Once the source files are added to the JARVICE vault, those files will be available in each compute node on `/data`. 
 
 Use SFTP with your JARVICE Material Compute credentials to transfer the files to `drop.jarvice.com` using a client such as [Filezilla](https://filezilla-project.org/index.php) or [Cyberduck](https://cyberduck.io/). 
 
  
 **Note**: further info on JARVICE file transfers [here](https://nimbix.zendesk.com/hc/en-us/articles/208083526-How-do-I-transfer-files-to-and-from-JARVICE)

## Login to JARVICE
 
Navigate to the [JARVICE Material Compute](https://platform.jarvice.com) site and login with your Nimbix credentials. Select [Compute]() on the right. Scroll down the list of applications to the SDAccel applications or select **Xilinx** from the [Vendors]() panel on the left. 

## Start the SDAccel Development application

Select the `SDAccel Development` application which will launch the application panel to choose the `Gui` option and then select the desired JARVICE Machine type. The application will start, select the preview image to connect to the SDAccel environment.

#### Direct compilation output to the JARVICE data store

The compiler output should write output the to the `/data` directory. When later running the `SDAccel Runtime`, the compiled `.exe` will be available to run from this directory without the need to transfer files.
 
## Create the OpenCL application with the SDAccel Environment

_...Insert Xilinx compilation instructions here..._

**Note**: Xilinx has a document for SDAccel as well: [Getting Started with the SDAccel Environment on Nimbix Cloud](http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_2/ug1240-sdaccel-nimbix-getting-started.pdf)

## Run the compiled OpenCL application 

Select the `SDAccel Runtime` application which will launch the application panel to choose the `Batch` option and then select the desired JARVICE Machine type. The Machine type must match the SDAccel application target. The Machine type drop down will show the associated Xilinx FPGA.
 
 From the `Executable` parameter use the file chooser `...` to select the compiled `.exe` previously saved to `/data`. Press the `Submit` button run the job.