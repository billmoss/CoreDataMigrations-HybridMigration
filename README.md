CoreDataMigrations-HybridMigration
==================================

Demo 5 project from my Core Data Migrations talk at San Antonio iOS Meetup.

This demo uses the same configuration of *Demo 4 Lightweight Migration* but replaces the code in CDMRootViewController in openPersistentStore to instantiate a CDMMigrationManager class which handles the hybrid migration.

Script
------
1. Delete app and data from the simulator.
2. Set current model to Model1. Run app to generate baseline database.
3. Quit app. 
4. Set current model to Model5.
5. Run app and open the store.
6. The console log will show evidence of 4 migrations. 3 custom and one lightweight.
7. Review the Topics tableView. We show valid topics with timeBudgets in seconds, set by the length of the topic itself, and properly factored Topic/Member entities.
8. Demo ends.
