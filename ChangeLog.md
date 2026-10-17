# Revision history for Vis

## Functional Versions

### 0.3.2 -- 2026-10-17
* Reflowed the README and documentation to remove hard wrapping.
* Added a blank line above the demo's main header line.
* Changed the demo to read single keys without a prompt or Enter.
* Fixed the Exit key highlight in the demo menu.
* Documented the evaluation of the proposed monadic Printer and Section interface.

### 0.3.1 -- 2026-10-17
* Removed the extra solid bar from the demo header, which covered part of the second line.
* Made the demo footer shortcuts functional with an interactive screen loop.
* Documented the decision to defer the Text and Seq migrations.

### 0.3.0 -- 2026-10-17
* Revival release: removed Example and internal modules from the public Vis module.
* Added public Vis.Number and Vis.Sample modules.
* Added the vis-demo executable and the vis-test suite.
* Made paragraph wrapping, list layout and group layout total for empty and narrow inputs.
* Fixed a division by zero in group overflow handling.
* Preserved section line counts across chained replace calls.
* Added documentation in docs/ and rewrote the README as an index.
* Enabled -Wall and cleaned compiler warnings.

## Early Versions

### 0.2.2.7 -- 2020-05-29
* Implementation of Sample instance for VisNumber.
* Refining of Sample class and instances for all types.

### 0.2.2.5 -- 2020-05-23
* Got rid of the Result type and module.
* Reversal of Show instances to default, creation of Sample class.
* Implementation of sample functions.
* Created Printer for single Item.

### 0.2.2.1 -- 2020-05-21
* Implemented minimum number of lines for Sections.

### 0.2.2.0 -- 2020-05-20
* Finished amend functionality for VisPage and workflow.
* Made Settings update at each redraw.
* Created the new VisConfig type for internal use.
* Made VisSettings the user exposed settings type.
* Made the basic Run functions work with configs, not settings.
* Created Draw module and internal State module.

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
