# Revision history for Vis


## Early Versions

### 0.2.1.4 -- 2020-05-19
* Exposed the basic builders.
* Reworked type runners to deal with IO separately.
* Defined VisState type and top level functionality.
* Created VisResult type to associate printed line numbers with Sections.
* Separated VisPage internal functionality.

### 0.2.0.9 -- 2020-05-09
* Gave up on verbose mode.
* Moved VisPrinter type to internal module.
* Reworked Show instances for most types and VisPrinter.
* Reworked Show instance for VisSection and moved type to internal module.

### 0.2.0.5 -- 2020-05-08
* Made VisItem remove non-printable characters.
* Creation of Internal folder to separate internal modules.
* Creation of Show Instances to implement the Verbose mode.
* Implementation of Settings type and functions.
* Improved Section type to calculate the total printed lines.

### 0.2.0.0 -- 2020-05-07
* Major change so VisPrinter returns the number of lines printed.
* Major refactoring and module splits.

### 0.1.1.0 -- 2020-04-25
* VisPrinter functionality implemented.

### 0.1.0.5 -- 2020-04-19
* Restarted project.
* Implemented basic content types and styles.

### 0.1.0.0 -- 2018-06-12
* First version, very basic functionality, not commited to VCS.
