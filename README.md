# AllAboutEKS-clusterAndSetup
This repository is dedicated to how you can setup an eks cluster with ALB.


To Create cluster with oidc provider attached use the first script (clusterAndSetup,sh).

make sure it has executable permissions. It is a bash script which will ask you all the required details about your cluster and zones with computer machine size and etc.

After creating a cluster try to deploy an application with yourself by writing the deployment,service and ingress yaml files for your application.

After that you can either expose the port on which your application service is running otherwise you can install and configure Application Load Balancer on top of your application so that no one should be able access the application directly from the public ip address.

After creating and applying the ingress.yaml file you just have created for you application. Now you can install alb. To install the alb on eks cluster use the second shell script (configure-alb-eks.sh).

This shell script will ask you some questions related to your cluster,zones,regions and etc. Kindly fill correctly otherwise the script wont work.

Now you can access you application using ALB service. just search loadbalancer on the searchbar of aws console. After that click on it and it will show you a application load balancer, just click on it, copy the dns url and paste it on your favourate browser. 
