# Configuração de Servidor DNS Autoritativo com BIND9

## Índice

- [Objetivo](#objetivo)
- [Topologia](#topologia)
- [Compreensão dos requisitos](#compreensão-dos-requisitos)
- [Instalação do bind9](#instalação-do-bind9)
- [Configuração do bind9](#configuração-do-bind9)
  - [Criação e configuração da zona direta](#criação-e-configuração-da-zona-direta)
  - [Declaração da zona no named.conf.local](#declaração-da-zona-no-namedconflocal)
  - [Configuração de opções globais](#configuração-de-opções-globais)
- [Verificação das configurações](#verificação-das-configurações)
- [Testar o serviço de DNS](#testar-o-serviço-de-dns)

## Objetivo

Este repositório é destinado a armazenar a documentação de configuração de servidor autoritativo DNS utilizando o pacote BIND9 no Ubuntu Server 24.04.2 para a empresa fictícia Technocorp.

## Topologia

A configuração será baseada na seguinte tabela de Resources Records[<sup>1</sup>](https://en.wikipedia.org/wiki/Domain_Name_System#Resource_records)

| Nome | Classe | Tipo  | Prioridade | Host                | Comentário                         |
| ---- | ------ | ----- | ---------- | ------------------- | ---------------------------------- |
| @    | IN     | NS    |            | ns1.technocorp.emp  | Servidores de nome                 |
| ns1  | IN     | A     |            | 127.0.0.1           | A Records para Servidores de Nomes |
| @    | IN     | A     |            | 127.0.0.1           | A Records                          |
| ftp  | IN     | A     |            | 127.0.0.1           | A Records                          |
| mail | IN     | A     |            | 127.0.0.1           | A Records                          |
| dhcp | IN     | A     |            | 127.0.0.1           | A Records                          |
| dns  | IN     | A     |            | 127.0.0.1           | A Records                          |
| www  | IN     | CNAME |            | @                   | CNAME Records                      |
| mail | IN     | MX    | 10         | mail.technocorp.emp | MX Records                         |

## Compreensão dos requisitos

- Distribuição Ubuntu Server na versão 24.04.x
- Acesso ao usuário `root` ou usuário com sudo
- Meio para instalação dos pacotes (geralmente acesso à Internet)
- Editor de texto (ex: `nano`, `vim`, `micro`)

## Instalação do bind9

Utilizaremos o comando abaixo para a instalação dos pacotes bind9 e relacionados

```shell
sudo apt install bind9 bind9utils bind9-doc dnsutils -y
```

#### Detalhes de cada pacote:

|    Pacote    | Distribuição                                                             |
| :----------: | ------------------------------------------------------------------------ |
|   `bind9`    | Servidor DNS (Serviço principal)                                         |
| `bind9utils` | Ferramentas auxiliares como `rndc`, `named-checkconf`, `named-checkzone` |
| `bind9-doc`  | Documentação oficial do BIND9 (instalada em `/usr/share/doc/bind9-doc`). |
|  `dnsutils`  | Ferramentas de teste como `dig`, `nslookup` e `host`                     |

## Configuração do bind9

### Criação e configuração da zona direta

Para facilitar a criação do arquivo de zona, iremos cria-lo a partir de uma copia de `/etc/bind/db.local`

```shell
sudo cp /etc/bind/db.local /etc/bind/db.technocorp.emp
```

E em seguida vamos editar o arquivo com o comando:

```shell
sudo editor /etc/bind/db.technocorp.emp
```

> [!important]
> Lembre-se de substituir `editor` pelo editor de sua preferência (ex: `nano`, `vim`, `micro`, `emacs`).

Ao abrir o arquivo, o seu conteúdo atual pode ser algo parecido com isso:

```bind9
;
; BIND reverse data file for local loopback interface
;
$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      localhost.
1       IN      PTR     localhost.
```

O conteúdo acima ainda é da versão original do arquivo (`/etc/bind/db.local`) que contem um modelo padrão de zona reversa [<sup>2</sup>](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/reference_guide/s2-bind-configuration-zone-reverse) utilizado para resolução reversa [<sup>3</sup>](https://en.wikipedia.org/wiki/Reverse_DNS_lookup), que retorna o endereço de loobpack [<sup>5</sup>](https://en.wikipedia.org/wiki/Loopback#Virtual_loopback_interface) `127.0.0.1`, por isso o seu conteúdo é simples, possuindo apenas um PTR Record [<sup>5</sup>](https://docs.redhat.com/en/documentation/red_hat_openstack_platform/17.0/html/using_designate_for_dns-as-a-service/manage-pointer-records_rhosp-dnsaas#ptr-record-basics_manage-pointer-records) [<sup>6</sup>](https://www.cloudflare.com/learning/dns/dns-records/dns-ptr-record)  apontando IP `127.0.0.1` para `localhost`, o que não seria adequado para o nosso cenário. Então, seguindo como os requisitos documentados em [Topologia](#Topologia) o conteúdo do arquivo deve configurar uma zona direta [<sup>7</sup>](https://en.wikipedia.org/wiki/DNS_zone#Forward_DNS_zones) [<sup>8</sup>](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_networking_infrastructure_services/assembly_setting-up-and-configuring-a-bind-dns-server_networking-infrastructure-services#proc_setting-up-a-forward-zone-on-a-bind-primary-server_assembly_configuring-zones-on-a-bind-dns-server) necessária para o nosso domínio fictício da Technocorp, então assim teremos:

```bind9
;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	ns1.technocorp.emp. admin.technocorp.emp. (
         2025060602		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
; Servidores de Nomes
@			IN			NS		ns1.technocorp.emp.

; A Records para Servidores de Nomes
ns1 		IN			A 		127.0.0.1

; A Records para Subdomínios
@			IN			A 127.0.0.1
www 		IN 			A 127.0.0.1
dns 		IN 			A 127.0.0.1
dhcp 		IN 			A 127.0.0.1
ftp 		IN 			A 127.0.0.1
mail 		IN 			A 127.0.0.1

; CNAME
www     IN      CNAME   @

; MX Record
@       IN      MX 10   mail.technocorp.emp.
```

Agora falando um pouco sobre as diferenças dos arquivos podemos perceber que ao configurar uma Forwarding Zone (ou zona direta), temos definidos os seguintes elementos:
- Servidor de nome autoritativo `ns1.technocorp.emp` por registros `NS` e `A`
- Diversos subdomínios (`www`, `dns`, `dhcp`, `ftp`, `mail`) apontando para endereços locais específicos todos com registros `A`
- Um registro (alias) do tipo `CNAME` de `www` que aponta para o domínio raiz (`@`), o que evita repetição de IP pois "recebe" o host do registro `@` ou `technocorp.emp`
- Um registro do tipo `MX` que defini o servidor de e-mails da zona, apontando para `mail.technocorp.emp`
- Alteração no valor Serial de `2` para `2025060602`que segue a convenção de basear o valor na data

### Declaração da zona recém criada no arquivo de zonas

Agora vamos utilizar o seguinte comando para declarar a zona recém criada:

```shell
sudo editor /etc/bind/named.conf.local
```

E lá vamos inserir o conteúdo abaixo que informa ao bind9 que ele é a autoridade responsável pela zona `technocorp.emp` e informa o caminho do arquivo de registro da zona.

```bind9
zone "technocorp.emp" {
    type master;
    file "/etc/bind/db.technocorp.emp";
};
```

#### Detalhes sobre a stanza

Na linha 1 temos `zone "technocorp.emp"`que define o nome da zona a ser referenciada, enquanto na 2 temos `type master;` que define o servidor como autoridade sobre a zona, a 3 com `file "/etc/bind/db.technocorp.emp";`definindo o o **caminho absoluto** do arquivo de registro daquela zona e por último a 4 com `};` fechando as chaves abertas na 1 e finalizando a definição da regra.

### Configuração de opções globais do bind9


Além da criação e configuração da zona, é importante verificar e ajustar as **opções globais do servidor BIND**, geralmente definidas no arquivo `/etc/bind/named.conf.options`.

Além da criação e configuração de uma zona, precisamos verificar e ajustas algumas opções globais do nosso servidor, para isso vamos usar o comando abaixo para editar o arquivo responsável:

```shell
sudo editor /etc/bind/named.conf.options
```

E nele cole o seguinte conteúdo:

```bind9
options {
    directory "/var/cache/bind";

    recursion yes;
    allow-query { localhost; };

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;
    auth-nxdomain no;
    listen-on { any; };
};
```

#### Detalhamento sobre os parâmetros utilizados em cada linha

| Diretiva                      | Descrição                                                                                                                                          |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `directory`                   | Aqui definimos onde o BIND armazena arquivos temporários e de cache, não precisa ser alterado.                                                     |
| `recursion yes;`              | Permite ao servidor realizar consultas recursivas (buscar por outras zonas além das que ele é autoritativo).                                       |
| `allow-query { localhost; };` | Restringe as consultas DNS ao próprio servidor (mais seguro em ambientes locais). Pode ser ampliado para redes específicas, como `192.168.0.0/24`. |
| `forwarders`                  | Define servidores DNS externos (ex.: Google DNS) para os quais o BIND encaminhará as consultas que ele não puder resolver localmente.              |
| `dnssec-validation auto;`     | Ativa a validação de segurança DNSSEC automaticamente. Pode ser deixada como está em testes locais, ou desabilitada com `no;` se causar problemas. |
| `auth-nxdomain no;`           | Compatibilidade com RFCs. Usar `no` evita que o servidor se declare autoritativo por padrão para domínios inexistentes.                            |
| `listen-on { any; };`         | Define em quais interfaces de rede o servidor vai escutar. `any` permite em todas; pode ser restrito (ex.: `127.0.0.1;` para uso local apenas).    |

## Verificação das configurações
- dos arquivos de configuração com `sudo named-checkconf`
- do arquivo da zona criada com `sudo named-checkzone technocorp.emp /etc/bind/db.technocorp.emp`

Tudo pronto, mas antes de habilitarmos o serviço vamos verificar se está tudo configurado corretamente, para isso utilize:

**Para validar a sintaxe dos arquivos de configuração (`named.conf`, `named.conf.local`)**

```shell
sudo named-checkconf
```

**Saída esperada:** Nenhuma mensagem significa que está tudo correto.

---

**Para verificar o arquivo de definição de zona `/etc/bind/db.technocorp.emp`**

```shell
sudo named-checkzone technocorp.emp /etc/bind/db.technocorp.emp
```

**Saída esperada:**

```
zone technocorp.emp/IN: loaded serial 2025060602
OK
```

Após teste e confirmação de que tudo está certo, ative e inicie o serviço:

Habilitar inicialização automática do bind9 com o sistema:

```shell
sudo systemctl enable bind9
```

---

Reiniciar o serviço do bind9:

```shell
sudo systemctl restart bind9
```

---

Verificar o estado do serviço:

```shell
sudo systemctl status bind9
```

- é importante notar se o estado está como `active (running)`, caso contrario terá tido falha e encontrará alguma mensagem de erro nas linhas finais
- Aperta `q` para sair da tela e voltar normalmente ao terminal

## Testar o serviço de DNS
- Pela própria máquina
- Por outra máquina (Windows)

#### Teste local (no próprio servidor)

Caso tenha instalado as ferramentas e pacotes extras em [Instalação do bind9](#Instalação do bind9) então poderá testes de forma local utilizando o `dig`:

```shell
dig @127.0.0.1 technocorp.emp
dig @127.0.0.1 www.technocorp.emp
dig @127.0.0.1 mail.technocorp.emp MX
```

#### Teste a partir de outra máquina (Windows)

No terminal do Windows (CMD ou PowerShell), execute os comandos abaixo para definir temporariamente o DNS para apontar ao seu servidor e testar requisições dos subdomínios configurados:

```
nslookup
> server [IP_DO_SERVIDOR]
> technocorp.emp
> www.technocorp.emp
> mail.technocorp.emp
```

E para sair utilize `> exit`


# Referencias

[List of DNS Record Types - Wikipedia](https://en.wikipedia.org/wiki/List_of_DNS_record_types)
[Domain Name System, Resource Records - Wikipedia](https://en.wikipedia.org/wiki/Domain_Name_System#Resource_records)
[MX Records - Wikipedia](https://en.wikipedia.org/wiki/MX_records)
[Setting up a forward zone on a BIND primary server - RedHat](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_networking_infrastructure_services/assembly_setting-up-and-configuring-a-bind-dns-server_networking-infrastructure-services#proc_setting-up-a-forward-zone-on-a-bind-primary-server_assembly_configuring-zones-on-a-bind-dns-server)
[PTR record basics - RedHat](https://docs.redhat.com/en/documentation/red_hat_openstack_platform/17.0/html/using_designate_for_dns-as-a-service/manage-pointer-records_rhosp-dnsaas#ptr-record-basics_manage-pointer-records)
[DNS PTR Record - Cloudflare](https://www.cloudflare.com/learning/dns/dns-records/dns-ptr-record/)
[Virtual Loopback Interface - Wikipedia](https://en.wikipedia.org/wiki/Loopback#Virtual_loopback_interface)
[Reverse DNS Lookup](https://en.wikipedia.org/wiki/)
[Reverse Name Resolution Zone Files - RedHat](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/reference_guide/s2-bind-configuration-zone-reverse)
[Conteúdo padrão de /etc/bind/db.local - ChatGPT](https://chatgpt.com/c/68523315-c198-800a-b1a6-c02d35872d86)
