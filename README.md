# Presentation

This is a modified version of CloudFactory implementing XXX.  
It was used to evaluate XXXX.  

```bash
python -m generator --distribution=examples-scenario/scenario-vm-distribution-ovhcloud2023.yml --usage=examples-scenario/scenario-vm-usage-azure2017-fatinc.yml --vm=12 --output=bash --temporality=90,900,48
```

## Simulation experiments

Generate workload for our XXXX simulation (CloudSimPlus based):
```bash
python3 -m generator --distribution=examples-scenario/scenario-vm-distribution-ovhcloud2023.yml --usage=examples-scenario/scenario-vm-usage-azure2017.yml --vm=100 --temporality=360,8640,7 --output=cloudsimplus 
cloudsimplus_repo='/usr/local/src/cloudsimplus-vcpupinning/'
host_count=1
host_cpu=32
host_gb=128
java -cp $cloudsimplus_repo/target/cloudsimplus-*-with-dependencies.jar org.cloudsimplus.examples.CloudFactoryGeneratedWorkload $host_count $host_cpu $host_gb no vms.properties models.properties false
```

If one wants to deduct the minimal number of servers needed for the workload, this is done through this script that will sequentially launch simulation starting at ```$host_count```:
```bash
label="test"
vm_count=100
host_count=1
vcluster-experiments-data/deduct-min.sh $label $vm_count $host_count no vms.properties models.properties false
```

For comparison purposes, if you want to compute the number of server needed to host VMs from a specific oversubscription level (in a classic setting where an oversubscription level is hosted in a single cluster):
```bash
filer_oc=1.0
vcluster-experiments-data/deduct-min.sh $label $vm_count $host_count $filer_oc vms.properties models.properties false
```

Finally, if you want to compute, the number of servers required for all oversubscriptions levels distribution on both classic clusters and a SlackVM cluster: 
```bash
distribution="ovhcloud2023"
vcluster-experiments-data/cluster-sizing-exp.sh $distribution
```
> This is a time consuming step. Count for at least 12h

## Physical experiments

Generate workload for our VMSlack prototype (must be running before executing setup and workload scripts):
```bash
python3 -m generator --distribution=examples-scenario/scenario-vm-distribution-ovhcloud2023.yml --usage=examples-scenario/scenario-vm-usage-azure2017.yml --premium=examples-scenario/scenario-vm-premium.yml --vm=100 --temporality=400,3600,10 --output=bash
./setup.sh
./workload-local.sh
```

# Below : Initial CloudFactory README file

CloudFactory is a IaaS workload generator. Its goals is to generate representative workloads for simulators (such as CloudSimPlus) or for physical platforms (using bash scripts or CBTOOL)

CloudFactory is composed of two elements : 
- A library able to analyze a cloud dataset and generate a workload scenario. Its usage is illustrated in jupyter notebooks at folder root.
- A generator parsing a scenario and generating specified output (bash script, CloudSim scenario, CBTOOL scenario)

## Setup

```bash
apt-get update && apt-get install -y git python3 python3.venv
git clone https://github.com/jacquetpi/cloudfactory-vcpupinning
cd cloudfactory/
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
python3 -m generator --help
```

## Analyzer Example

We provide an example using Microsoft Azure public dataset in our notebook. To launch it:
```bash
source venv/bin/activate
jupyter notebook
```
Select `build_a_scenario.ipynb` and follow instructions

Generated statistics are described in two Yaml files : `scenario-vm-distribution.yml`(containing VM configuration options distribution) and `scenario-vm-usage.yml`(containing usage related metrics).  
Files can be passed to workload generator with its `--distribution=` and `--usage=` arguments.  
If not specified, generator will use `examples-scenario/scenario-vm-distribution.yml` and `examples-scenario/scenario-vm-usage.yml` values.

## Generator Example : CloudSimPlus

CloudFactory can generate a simulation scenario using CloudSimPlus.
Following example generates a default scenario targeting a workload with 256 cores and 512GB at its initialization phase.

```
python3 -m generator --cpu=256 --mem=512 --output=cloudsimplus
cloudsim_repo="/usr/local/src/cloudsimplus-examples"
mv CloudFactoryGeneratedWorkload.java "$cloudsim_repo"/src/main/java/org/cloudsimplus/examples/
mv *.properties "$cloudsim_repo"
cd "$cloudsim_repo"
mvn clean install
java -cp target/cloudsimplus-examples-*-with-dependencies.jar org.cloudsimplus.examples.CloudFactoryGeneratedWorkload
```
Refer to CloudSimPlus example [repository](https://github.com/cloudsimplus/cloudsimplus-examples) for more details

## Generator Example : Bash

Generate a bash IaaS workload by provisioning 10 VMs:

`python3 -m generator --vm=10 -t600,1800,36 --output=bash`

`t` or `--temporality` specify our virtual hours and days duration. Here, an `hour` lasts 600s, a `day` 1800s (`day` must be a multiple of `hour`). Our workload is composed of 36 virtual `days`

While we provide bash scripts to generate a given workload, VM template are user dependant.
To quickly setup environments, we rely on pre-built qcow2 images with ssh-keys installed.

In the basic implementation, 3 different images are used:

- A baseline image, with stressng, docker and a non-deployed DeathStarbench environment
- PostgresQL image installed with a TPC-C schema
- Wordpress image

The baseline image is used for different workloads (idle, stressng, Deathstarbench) as installation scripts are different between workload.

Values passed to programs are adapted from CloudFactory generated CPU usage.
Conversion is approximative and may be customised using `examples-workload\scenario-vm-workload.yml`

## Generator Example : CBTOOL

More complex deployments can be managed with CBTOOL deployments.
Following example generates a CBTOOL compatible scenario, running on its simulation mode, which can be adapted to others cloud deployments.

```
python3 -m generator --cpu=256 --mem=512 --output=cbtool
cbtool_repo="/usr/local/src/cbtool"
mv cloudfactory.cbtool "$cbtool_repo"
cd "$cbtool_repo"
cbtool/cb --trace=cloudfactory.cbtool
```
Refer to CBTOOL [repository](https://github.com/ibmcb/cbtool) for more details
