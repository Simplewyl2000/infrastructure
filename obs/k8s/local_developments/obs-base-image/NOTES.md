#Notes for mysql
(Use arrows or pgUp/pgDown keys to scroll the text by lines or pages.)

Message from package mariadb:


You just installed MySQL server for the first time.

You can start it using:
 rcmysql start

During first start empty database will be created for your automatically.

PLEASE REMEMBER TO SET A PASSWORD FOR THE MariaDB root USER !
To do so, start the server, then issue the following commands:

'/usr/bin/mysqladmin' -u root password 'new-password'
'/usr/bin/mysqladmin' -u root -h <hostname> password 'new-password'

Alternatively you can run:
'/usr/bin/mysql_secure_installation'

which will also give you the option of removing the test
databases and anonymous user created by default. This is
strongly recommended for production servers.