This project contains a workflow (file UmlToAppGenerator.mwe2 in src/umlToApp.workflow), which transforms 
a UML class diagramm with stereotypes (possibly created with Papyrus) into a set of Java classes 
and a corresponding DDL with a database schema (e.g. for MySQL).

The source directory of the model and the target directory can be determined in the first lines
of the workflow.

The workflow uses a generator, which can be found in file UmlToAppGenerator.xtend (in 
de.wwu.pi.mdsd.umlToApp).

The workflow can be started by: 
Run as (available in the centext menu (right mouse click)) -> MWE2 Workflow