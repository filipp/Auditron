##Welcome##
Auditron is a tool for collecting information about Macs via email and then reporting the results. It's useful for remote
troubleshooting or even performing remote audits of offices running Macs.

##How it works##
The user launches the application
which runs system_profiler and either tells the user's mail agent (currently Mail.app and Entourage are supported) 
to create a new email with the System Profiler report as an attachment. The user can save the profile somewhere
in case the mailer is not identified.

The results can then easily reported on by using the File > Compare Results command. This scans a directory for any compressed
SPX files and builds a report which can then be exported as a CSV file.

##Bugs and limitations##
Currently only a very small subset of the SP report can be reported.