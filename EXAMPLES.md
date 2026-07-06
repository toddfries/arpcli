# arpcli examples

Sample command output for documentation. Account-specific fields are **defanged**:
UUIDs use `xxxx` placeholders, hostnames use `example.com`, and IPv4/IPv6 use
documentation addresses (`xxx.x.xxx.0/24`, `2001:db8::/32`). Catalog data
(plans, locations, ISOs, OS templates) is real public API shape.

---

## plans list

```
$ arpcli plans list
VPS
ID CODE             NAME             Price          Specs        
                                     monthly hourly Disk RAM  CPU
1  vps_small        Small Plan       10.00   0.0137 40   1024 2  
2  vps_medium       Medium Plan      15.00   0.0205 40   1536 2  
3  vps_all_purpose  All-Purpose Plan 20.00   0.0274 40   2048 2  
4  vps_large        Large Plan       30.00   0.0411 80   3072 2  
5  vps_jumbo        Jumbo Plan       40.00   0.0548 160  4096 2  
6  vps_the_american The American     60.00   0.0822 240  8192 2  

ARP Thunder
# Disk: primary Storage + Storage (SATA) bulk capacity (API names; not detailed in OpenAPI)
ID CODE               NAME             Price          Specs            
                                       monthly hourly Disk    RAM   CPU
7  thunder_starter    Starter Plan     40.00   0.0548 80+200  4096  2  
8  thunder_medium     Medium Plan      60.00   0.0822 120+300 6144  3  
9  thunder_allpurpose All-Purpose Plan 80.00   0.1096 160+400 8192  4  
10 thunder_large      Large Plan       120.00  0.1644 200+500 16384 8  
```

## plans list --thunder

```
$ arpcli plans list --thunder
ARP Thunder
# Disk: primary Storage + Storage (SATA) bulk capacity (API names; not detailed in OpenAPI)
ID CODE               NAME             Price          Specs            
                                       monthly hourly Disk    RAM   CPU
7  thunder_starter    Starter Plan     40.00   0.0548 80+200  4096  2  
8  thunder_medium     Medium Plan      60.00   0.0822 120+300 6144  3  
9  thunder_allpurpose All-Purpose Plan 80.00   0.1096 160+400 8192  4  
10 thunder_large      Large Plan       120.00  0.1644 200+500 16384 8  
```

---

## servers list

```
$ arpcli servers list
LABEL           UUID                                 STATE   PLAN              IPv4         
relay1.example.com xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Small Plan  xxx.x.xxx.10
ns3.example.com    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Custom Plan xxx.x.xxx.11
mail.example.com   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Small Plan  xxx.x.xxx.12
```

## servers list --json

```
$ arpcli servers list --json
{
   "meta" : {
      "pagination" : {
         "aggregated" : true,
         "total_entries" : 3
      }
   },
   "servers" : [
      {
         "billing_interval" : "monthly",
         "billing_mode" : "reserved",
         "created_at" : "2009-09-02T11:11:44Z",
         "ip_space" : "Reserved",
         "label" : "relay1.example.com",
         "location" : "LAX",
         "os_template" : "openbsd-7.6-amd64",
         "plan" : "VPS - Small Plan",
         "primary_ipv4" : "xxx.x.xxx.xx",
         "primary_ipv6" : "2001:db8:1234::2",
         "provisioning_status" : "active",
         "specs" : [
            { "name" : "CPU", "quantity" : "1.0", "unit" : "core" },
            { "name" : "RAM", "quantity" : "256.0", "unit" : "MB" },
            { "name" : "Storage", "quantity" : "10.0", "unit" : "GB" }
         ],
         "state" : "running",
         "uuid" : "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      }
   ]
}
```

(JSON truncated to one server for brevity; live output lists all pages.)

## servers show

```
$ arpcli servers show xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
billing_interval=monthly
billing_mode=reserved
created_at=2009-09-02T11:11:44Z
ip_space=Reserved
label=relay1.example.com
location=LAX
os_template=openbsd-7.6-amd64
plan=VPS - Small Plan
primary_ipv4=xxx.x.xxx.xx
primary_ipv6=2001:db8:1234::2
provisioning_status=active
specs=CPU=1core, RAM=256MB, Storage=10GB
state=running
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## servers bandwidth

```
$ arpcli servers bandwidth xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
range=30d
inbound_bytes=1.57 GB
outbound_bytes=1.66 GB
total_bytes=3.23 GB
```

---

## locations list

```
$ arpcli locations list
FRA	DE	Frankfurt (FRA)	Frankfurt
LAX	US	Los Angeles (LAX)	Los Angeles
```

## isos list (sample)

```
$ arpcli isos list
AlmaLinux-10.1-x86_64-boot.iso
CentOS-Stream-9-x86_64-boot.iso
Fedora-Server-netinst-x86_64-43-1.6.iso
FreeBSD-14.4-RELEASE-amd64-disc1.iso
openbsd-amd64-install70.iso
```

## os-templates list (sample)

```
$ arpcli os-templates list
CODE                       FAMILY    VERSION           
almalinux-10.1-amd64       almalinux 10.1              
debian-13-amd64            debian    13 (Trixie)       
fedora-43-amd64            fedora    43                
freebsd-15.1-amd64-zfs     freebsd   15.1-RELEASE (ZFS)
openbsd-7.6-amd64          openbsd   7.6               
rocky-10.1-amd64           rocky     10.1 (Red Quartz) 
```

## dns-records list

```
$ arpcli dns-records list
ID    NAME                      CONTENT            DOMAIN                
3596  10.113.0.203.in-addr.arpa ns3.example.com.   113.0.203.in-addr.arpa
11467 11.113.0.203.in-addr.arpa mail.example.com.  113.0.203.in-addr.arpa
17545 12.113.0.203.in-addr.arpa relay1.example.com. 113.0.203.in-addr.arpa
```

## ssh-keys list

```
$ arpcli ssh-keys list
ID NAME USERNAME TYPE
```

(Empty account — no SSH keys registered.)

---

## status (excerpt)

```
$ arpcli status
arp.account
  services.servers.count=3
  services.dns_records.count=3
  services.ssh_keys.count=0
  catalog.locations.count=2
  catalog.plans.count=10
  catalog.isos.count=42
  catalog.os_templates.count=24

arp.servers
  LABEL            UUID                                 STATE   PLAN              OS                IPv4         IPv6           
  mail.example.com 22264ad0-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Small Plan  openbsd-7.6-amd64 xxx.x.xxx.12 -              
  ns3.example.com  c767c910-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Custom Plan openbsd-7.6-amd64 xxx.x.xxx.11 2001:db8:af98::1
  relay1.example.com xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx running VPS - Small Plan  openbsd-7.6-amd64 xxx.x.xxx.10 2001:db8:1800::2

  server.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    billing_interval=monthly
    billing_mode=reserved
    created_at=2009-09-02T11:11:44Z
    ip_space=Reserved
    label=relay1.example.com
    location=LAX
    os_template=openbsd-7.6-amd64
    plan=VPS - Small Plan
    primary_ipv4=xxx.x.xxx.10
    primary_ipv6=2001:db8:1800::2
    provisioning_status=active
    specs=CPU=1core, RAM=256MB, Storage=10GB
    state=running
    bandwidth
      inbound_bytes=1.57 GB
      outbound_bytes=1.66 GB
      range=30d
      total_bytes=3.23 GB
    billing
      billing_mode=reserved
      interval=monthly
      total=10.00
      line_items
        VPS - Small Plan     qty=1    unit=10.0000  amount=10.00
    ssh_host_keys
      (none)

arp.dns_records
  ID    ARPA_NAME                 CONTENT              DOMAIN                
  xxxx  xx.xxx.0.203.in-addr.arpa ns3.example.com.     xxx.0.203.in-addr.arpa
  xxxxx xx.xxx.0.203.in-addr.arpa mail.example.com.    xxx.0.203.in-addr.arpa
  xxxxx xx.xxx.0.203.in-addr.arpa relay1.example.com.  xxx.0.203.in-addr.arpa

arp.ssh_keys
  (none)

arp.catalog
  locations
    FRA  Frankfurt            DE
    LAX  Los Angeles          US
  plans
    id=1    Small Plan            CPU=2core, RAM=1024MB, Storage=40GB  hourly=$0.0137 monthly=$10.0000
    ...
  isos
    count=42
    ...
  os_templates
    openbsd-7.6-amd64          openbsd      7.6
    ...
```

(Full `status` output continues with per-server detail for each UUID and the
complete catalog listings.)

---

## read-only key vs write

Write commands (`servers boot`, `dns-records create`, etc.) return HTTP 403 when
the API key lacks the `write` scope:

```
$ arpcli servers boot xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
arpcli: This API key does not have the 'write' scope
```
