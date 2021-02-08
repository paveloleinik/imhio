# About
```YML
Добрый день, меня зовут Павел Олейник.
До прошедшей пятницы я не был знаком с Terraform, поэтому
мой код может быть не совсем соответствовать best practices Terraform и быть не совсем чистый.

- Проект Terraform находиться в каталоге terraform
- Проект Ansible находиться в папке ansible
```

# Terraform
Инфраструктура развёрнута в облаке AWS. 
#### Структура проекта:
-	imhio.tf
-	variables.tf
#### Для создания инфраструктуры необходим пользователь с правами на создание:
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
- После запуска playbook запросит access_key ,secret_key , region. Необходимо ввести ключи от учетной записи имеющей права на создание объектов указанных выше. На Linux можно указать export AWS_ACCESS_KEY_ID=”” , export AWS_SECRET_ACCESS_KEY=””, export AWS_DEFAULT_REGION="" и закоментировать переменный в variables.tf. В случае смены региона (по умолчанию стоит us-east-2) так же нужно будет заменить переменную в ami в variables.tf

- Регион по умолчанию us-east-2 , можно поменять в переменной region
- Вы полнить команды для playbook Terraform:
  :--- 
  `terraform init` 
  `terraform plan`
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

