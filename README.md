# Generic Tools

*This repository is for generic purposes for personal usage.*

## Useful URL's

#### Moving Windows Recovery Partition Correctly
When a windows partition resize is needed but the Windows Recovery Partition is in way, the following content can help you to move/recreate the Recovery Partition:

[Moving Windows Recovery Partition Correctly](https://thedxt.ca/2023/06/moving-windows-recovery-partition-correctly/)



## Useful Commands

#### Removing emails from postfix mailqueue filtered by email address:
```
postqueue -p | tail -n +2 | awk 'BEGIN { RS = "" } /<mail address here>/ { print $1 }' | tr -d '*!' | postsuper -d -
```