# About
Добрый день, меня зовут Павел Олейник
До прошлой пятницы я никогда не работал с Terraform, поэтому я плохо знаком с best practices Terraform и мой код может быть не совсем чистый
Проект Terraform находиться в каталоге Terraform
Проект Ansible находиться в папке Ansible

# imhio
# Terraform
Инфраструктура развёрнута в облаке AWS. 
Структура проекта:
-	imhio.tf
-	variables.tf
Для создания инфраструктуры необходим пользователь с правами на создание:
- VPC
- Subnets
- Internet Gateway
- Elastic IP
- NACL
- Security group
- Route table
- EIN
- EC2 instance
!!! Необходим создать Access key или использовать существующие для создания объектов Terraform в AWS
!!! Необходим создать Key Pairs или использовать существующие для возможности подключения в instances после создания Terraform в AWS. Название Key Pair нужно указать в  переменной key_name в variables.tf

Перед выполнением playbook  Terraform, нужно изменить переменные в variables.tf :
ssh_white_ip – указать публичный адрес с которого будет происходить подключение по SSH
key_name– указать название key-pair, созданный заранее, для подключения к instances 
После запуска playbook запросит access_key и secret_key. Необходимо ввести ключи от учетной записи имеющей права на создание объектов указанных выше. Либо указать export AWS_ACCESS_KEY_ID=”” и export AWS_SECRET_ACCESS_KEY=”” и закоментировать переменный в variables.tf
Регион по умолчанию us-east-2 , можно поменять в переменной region

# Ansible
Структура проекта:
-	ansible.cfg
-	db.yaml
-	group_vars 
-	hosts 
-	roles
-	ssh.cfg
-	web.yaml 
ansible.cfg – конфигурационный файл ansible . Добавлена секция для подключения файла ssh.cfg
[ssh_connection]
ssh_args = -F ./ssh.cfg
 
db.yaml – Playbook для настройки DB instance в AWS, включает в себя роли.
- firewall 
- prepare_db
- imhio_db
group_vars – включает в себя общие переменные. Некоторые переменные не стал перемещать в роли для того что бы их проще было менять при необходимости.
- all содержит переменные:
	- mariadb_ip – IP адрес хоста с MariaDB 
	-  mariadb_bind_address – IP адрес котором запущена MariaDB
              - mariadb_port – порт MariaDB
	- mariadb_user – пользователь для подключения к MariaDB
	- mariadb_user_pass – пароль пользователя для подключения к MariaDB
	- mariadb_db_name – имя создаваемой базы данных для приложения tcg 
	- nginx_tcg_server_name – IP на котором запущен nginx
	- nginx_tcg_listen_port – порт на котором запущен  nginx
	- nginx_proxy_pass_server – IP адрес на который проектирует nginx
	- nginx_proxy_pass_port – порт адрес на который проектирует nginx
	- tcg_host - IP на котором запущен tcg
	- tcg_port - порт на котором запущен  tcg
	- block_name – имя блочного диска для дополнительного тома для БД
hosts -  каталог с инвентари ansible
-	all – файл инвентари absible
web – хост на котором запущен tcg, указан публичный IP
db – хост на котором запущена MariaDB, указан приватный IP в VPC AWS
roles – каталог с ролями ansible
-	firewall – отключение Firewall и Selinux
-	imhio_db – установка и настройка MariaDB. Для роли imhio_db использована роль ansible-galaxy https://github.com/bertvv/ansible-role-mariadb
-	
-	imhio_web – роль для настройки  Web хоста: установка и копирование конфигурационных файлов nginx и tcg, запуск служб
-	prepare_db – роль для подготовки DB хоста: разметка дополнительного тома, монтирование нового тома в /var/lib/mysql

 ssh.cfg – файл для подключения по приватному IP в AWS к хосту c БД через публичный IP Web сервера. В строке IdentityFile нужно указать Key Pair указанный при создании instances в AWS через Terraform

web.yaml – Playbook для настроки Web сервера в AWS, включает в себя роли: 
-	firewall
-	imhio_web

# Настройка хостов
!!! Необходим создать Access key или использовать существующие для создания объектов Terraform в AWS

#Развертывание стэнда
Вы полнить команды для playbook Terraform:
terraform init
terraform plan
terraform apply



Для настройки DB хоста необходимо выполнить playbook db.yaml в каталоге Ansible
ansible-playbook db.yaml
затем необходимо поменять IP адрес Web хоста созданный  при развертывание через Terraform в файле hosts/all.ini
Для настройки Web хоста необходимо выполнить playbook web.yaml в каталоге Ansible
ansible-playbook web.yaml
