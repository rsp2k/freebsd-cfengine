# cfengine inputs

* promises.cf - The main CFEngine configuration file
* update.cf - Contains promises for the agents, just to ensure that the latest promises are updated on the clients.
* failsafe.cf - This file is run by the agents if there are no configuration files found. It is being used by the agents in order to recover from a failure.
* cf-serverd.cf - Contains configuration for the CFEngine master servers
* cf-execd.cf - Contains configuration for the CFEngine Executor/Scheduler
* cf-report.cf - Contains configuration for the CFEngine self-knowledge extractor
* classes.cf - Global CFEngine classes.
* cleanup.cf - Contains configuration for tyding up of old files/directories.
