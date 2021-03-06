# Task

#### 1. Подготовить Terraform плейбук для настройки инфраструктуры с использованием модуля для Digital Ocean или AWS или GCP.

- 2 инстанса OS Centos 7.x
- оба инстанса подключены к одной частной сети для организации безопасного обмена
данными между приложением и БД
- ко второму инстансу подключен дополнительный внешний volume для хранения данных
базы
- firewall включен только для внешнего интерфейса
- в firewall по-умолчанию все порты закрыты для внешнего интерфейса
- ssh доступ ограничен по IP из публичных сетей
- для первого инстанса доступ из публичной сети по HTTP протоколу разрешен без
- ограничений

#### 2. Подготовить Ansible плейбук для развертывания приложения.

- разместить приложение tcg на первом инстансе
- для настройки приложения скопировать пример конфига: /etc/tcg/tcg.config.sample.json -> /etc/tcg/tcg.json
- публичный доступ к приложению должен быть организован через Nginx reverse proxy
- на втором инстансе настроить RDMS MySQL/MariaDB любой актуальной версии (>5.5)
- файлы MySQL разместить на внешнем volume
- создать БД для приложения и настроить к ней доступ по внутренней сети
- в конфигурационном файле приложения указать данные доступа к базе данных,
инициализация таблиц произойдет автоматически при первом запуске
- запустить приложение tcg через systemd , пакет приложения уже содержит все необходимые настройки, обеспечить автозагрузку при старте системы


# About
```YML
- Проект Terraform находиться в каталоге terraform. Terraform version 0.14.6
- Проект Ansible находиться в папке ansible. Ansible version 2.9.16
```

# Terraform
Инфраструктура развёрнута в облаке AWS. 
### Структура проекта:
-	main.tf
-	variables.tf
-	outputs.tf
-	ec2.tf
-	vpc.tf

#### main.tf
Основный настройки playbook
#### variables.tf
Переменные для playbook

#### outputs.tf

-	web_public_ip - публичный IP Web сервера
-	web_private_ip - приватный IP Web сервера
-	db_private_IP - приватный IP DB сервера
-	web_key_pair - имя ключа для по подключеня к Web inctance
-	db_key_pair - имя ключа для по подключеня к DB inctance
-	account_id - id AWS аккаунта в котором создается проект 
-	vpc_id - id созданого VPC
-	private_wb_cidr - cidr block приватной сети Web сервера 
-	private_db_cidr - cidr block приватной сети DB сервера 
-	web_sg_id - id security группы для Web сервера
-	db_sg_id - id security группы для DB сервера


#### ec2.tf
Настройки EC и связаннх объектов
#### vpc.tf
Настройки VPC и связаннх объектов

### Для создания инфраструктуры необходим пользователь с правами на создание:
- VPC
- Subnets
- Internet Gateway
- Elastic IP
- NACL
- Security group
- Route table
- EIN
- EC2 instance
- NAT Gateway


# Ansible
Структура проекта:
-	ansible.cfg
-	db.yaml
-	group_vars 
-	hosts 
-	roles
-	ssh.cfg
-	web.yaml 

#### ansible.cfg
конфигурационный файл ansible . Добавлена секция для подключения файла ssh.cfg
```Yaml
[ssh_connection]
ssh_args = -F ./ssh.cfg
```
#### db.yaml
Playbook для настройки DB instance в AWS, включает в себя роли.
- firewall 
- prepare_db
- imhio_db
#### group_vars
включает в себя общие переменные. Некоторые переменные не стал перемещать в роли для того что бы их проще было менять при необходимости.
- all содержит переменные:
	- `mariadb_ip – IP адрес хоста с MariaDB` 
	- `mariadb_bind_address – IP адрес котором запущена MariaDB`
	- `mariadb_port – порт MariaDB`
	- `mariadb_user – пользователь для подключения к MariaDB`
	- `mariadb_user_pass – пароль пользователя для подключения к MariaDB`
	- `mariadb_db_name – имя создаваемой базы данных для приложения tcg` 
	- `nginx_tcg_server_name – IP на котором запущен nginx`
	- `nginx_tcg_listen_port – порт на котором запущен  nginx`
	- `nginx_proxy_pass_server – IP адрес на который проектирует nginx`
	- `nginx_proxy_pass_port – порт адрес на который проектирует nginx`
	- `tcg_host - IP на котором запущен tcg`
	- `tcg_port - порт на котором запущен  tcg`
	- `block_name – имя блочного диска для дополнительного тома для БД`
#### hosts
каталог с инвентари ansible
- all – файл инвентари absible
	- `web – хост на котором запущен tcg, указан публичный IP`
	- `db – хост на котором запущена MariaDB, указан приватный IP в VPC AWS`
#### roles
каталог с ролями ansible
-	firewall – отключение Firewall и Selinux
-	imhio_db – установка и настройка MariaDB. Для роли imhio_db использована роль ansible-galaxy https://github.com/bertvv/ansible-role-mariadb
-	imhio_web – роль для настройки  Web хоста: установка и копирование конфигурационных файлов nginx и tcg, запуск служб
-	prepare_db – роль для подготовки DB хоста: разметка дополнительного тома, монтирование нового тома в /var/lib/mysql

#### ssh.cfg
файл для подключения по приватному IP в AWS к хосту c БД через публичный IP Web сервера. В строке IdentityFile нужно указать Key Pair указанный при создании instances в AWS через Terraform

#### web.yaml
Playbook для настроки Web сервера в AWS, включает в себя роли: 
-	firewall
-	imhio_web

# Развертывание инфраструктуры

## Terraform

### !!! Необходим создать Access key или использовать существующие для создания объектов Terraform в AWS
### !!! Необходим создать Key Pairs или использовать существующие для возможности подключения в instances после создания Terraform в AWS. Название Key Pair нужно указать в  переменной key_name в variables.tf


- Изменить переменную ssh_white_ip в variables.tf – указать публичный адрес с которого будет происходить подключение по SSH
- Создать Key Pair в регионе где будет развернута инфраструктура
- Изменить переменную key_name в variables.tf – указать название key-pair, созданный заранее, для подключения к instances 
- После запуска Terraform запросит access_key ,secret_key , region. Необходимо ввести ключи от учетной записи имеющей права на создание объектов указанных выше. На Linux можно указать export AWS_ACCESS_KEY_ID=”” , export AWS_SECRET_ACCESS_KEY=””, export AWS_DEFAULT_REGION="" и закоментировать переменный в variables.tf. В случае смены региона (по умолчанию стоит us-east-2) так же нужно будет заменить переменную в ami в variables.tf

- Регион по умолчанию us-east-2 , можно поменять в переменной region
- Вы полнить команды для playbook Terraform:
  :--- 
  `terraform init` 
  `terraform apply`
  `Ввести access_key`
  `Ввести region`
  `Ввести secret_key`
  - Сохранить Key Pair указанный в переменной key_name в variables.tf в корень папки ansible
  
### Ansible
Выполнить команды для playbook Ansible:
- Перед запуском плэйбуков необходимо сменить публичный IP в файле hosts/all.ini для Web сервера на публичный IP выданный для Web instance в облаке AWS при развертывание через Terraform .
```Yaml
[web_hosts]
web ansible_host=18.216.240.65

[db_hosts]
db ansible_host=10.0.2.200

[db_hosts:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ec2-user@18.216.240.65 -i ./test.pem"'
```
- Заменить публичный IP в файле ssh.cfg для host Web в поле Hostname и в поле ProxyCommand для Host 10.0.2.200
- Заменить в поле IdentityFile для обоих хостов ключ key.pem на название своего ключа
```Yaml
Host web
  Hostname 18.216.240.65
  StrictHostKeyChecking no
  User ec2-user
  IdentityFile ./key.pem
  ControlMaster auto
  ControlPersist 1m
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p

Host 10.0.2.200
  StrictHostKeyChecking no
  User ec2-user
  ProxyCommand ssh -W %h:%p ec2-user@18.216.240.65
  IdentityFile ./key.pem
 ``` 

- Для настройки DB хоста необходимо выполнить playbook db.yaml в каталоге Ansible ansible-playbook db.yaml
- Для настройки Web хоста необходимо выполнить playbook web.yaml в каталоге Ansible ansible-playbook web.yaml

