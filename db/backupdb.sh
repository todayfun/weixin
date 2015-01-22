#!/bin/bash
FILENAME=production.sqlite3`date +%Y%m%d`.gz
tar -zcvf /home/weixin/db/backup/$FILENAME /home/weixin/db/production.sqlite3