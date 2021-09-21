# Node/Express App CICD Automation

This Lab demonstrate the implementation of a DevOps CI/CD Pipeline using Git, Jenkins, Ansible, Terraform, Docker and Kubernetes on a virtual envirement created by Vagrant to deploy a node/express application.
#

Once the developer issues the commit and pushes the code to a specific branch on GitHub, a Jenkins job lanches to build the image, push it on Docker Hub then used in Dev or Test envirement (In this case : Kubernestes cluster) using Ansible or Terraform. 

## Prerequisites
02 Centos 8 servers
Must have Ansible, Terraform and Jenkins installed on build server
Must have a Kubernetes cluster

## The steps of this tutorial

1. Build Flask Docker image (build server) && Push it to Docker Hub
2. Deploy the application on dev/test server using Ansible
3. Create a jenkins Pipline for Terraform
4. Deploy the application on Kubernetes cluster using Terraform

### 1. Build Node/Express Docker image (build server) && Push it to Docker Hub

##### This is the playbook used for building and pushing the image (buildserver.yml)
~~~
---
- name: "Docker Image/Build and Image/Push"
  hosts: build
  become: true
  gather_facts: no
  vars_files:
    - docker.vars

  tasks:

    - name: "Build Step: Cloning Repository"
      git:
        repo: "{{ repo_url }}"
        dest: "{{ repo_dest }}"
      register: repo_status

    - name: "Build Step: Login to remote Repository"
      when: repo_status.changed == true
      docker_login:
        username: "{{ docker_username }}"
        password: "{{ docker_password }}"

    - name: "Build Step: Building image"
      docker_image:
        source: build
        build:
          path: "{{ repo_dest }}"
          pull: yes
        name: "{{ image_name }}"
        tag: "{{ item }}"
        push: true
        force_tag: yes
        force_source: yes
      with_items:
        - 1.0
~~~

### 2. Deploy the application on dev/test server using Ansible

##### This is the playbook used for deploying the application (devserver.yml)
~~~
- name: "Run Application using Docker On Dev Server"
  hosts: dev
  become: true
  gather_facts: no
  vars_files:
    - docker.vars

  tasks:

    - name: "Deploy Step: List of additional package Installation"
      yum:
        name:
        - git
        - python3-pip
        state: present

    - name: "Deploy Step: Python docker extension installation"
      pip:
        name: docker-py

    - name: "Deploy Step: Docker service restart & enable"
      service:
        name: docker
        state: restarted
        enabled: true
        
    - name: "Deploy Step: Run the mongo container"
      docker_container:
        name: mongodb
        image: "{{ mongo_image_name }}"
        recreate: yes
        pull: yes
        published_ports:
          - "27017:27017"
        env:
          - MONGO_INITDB_ROOT_USERNAME: "admin"
          - MONGO_INITDB_ROOT_PASSWORD: "password"
          
    - name: "Deploy Step: Run the mongo-express container"
      docker_container:
        name: mongodb-express
        image: "{{ mongo_express_image_name }}"
        recreate: yes
        pull: yes
        published_ports:
          - "8081:8081"
        env:
          - ME_CONFIG_MONGODB_ADMINUSERNAME: "admin"
          - ME_CONFIG_MONGODB_ADMINPASSWORD: "password"
          - ME_CONFIG_MONGODB_SERVER: "mongodb"

    - name: "Deploy Step: Run the container"
      docker_container:
        name: productApp
        image: "{{ image_name }}:1.0"
        recreate: yes
        pull: yes
        published_ports:
          - "8889:3000"
~~~

### Hosts file (hosts)
~~~
[build]
192.168.231.136

[dev]
192.168.231.137
~~~
- The IP address of the Build Server and Dev Server should be updated

### Ansible variable file (docker.vars)
~~~
repo_url: "https://github.com/Arboulahdour/nodejs-devops.git"
repo_dest: "/var/cicdLab/nodejs-devops"
image_name: "arboulahdour/nodejs-product"
mongo_image_name : "mongo"
mongo_express_image_name: "mongo-express"
docker_username: "arboulahdour"
docker_password: ""
~~~
- Some of these variables defined in the Ansible variable file (docker.vars) should be updated.

### 3. Create a jenkins Pipline for Terraform

##### This is the jenkinsfile used for this pipeline (jenkinsfile)
~~~
pipeline {
    agent any
    stages {
        stage('Getting Info') {
            steps {
                echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
            }
        }
        
        stage('TF Init&Plan') {
            steps {
                sh 'terraform init'
                sh 'terraform plan'
            } 
        }
        
        stage('TF Apply') {
            steps {
                sh 'terraform apply -input=false -auto-approve'
            }
        }

    }
}
~~~

### 3. Deploy the application on Kubernetes cluster using Terraform

##### This is the main Terraform's file used for the deployment in Kubernetes (main.tf)
~~~
- name: "Run Application using Docker On Dev Server"
  hosts: dev
  become: true
  gather_facts: no
  vars_files:
    - docker.vars

  tasks:

    - name: "Deploy Step: List of additional package Installation"
      yum:
        name:
        - git
        - python3-pip
        state: present

    - name: "Deploy Step: Python docker extension installation"
      pip:
        name: docker-py

    - name: "Deploy Step: Docker service restart & enable"
      service:
        name: docker
        state: restarted
        enabled: true
        
    - name: "Deploy Step: Run the mongo container"
      docker_container:
        name: mongodb
        image: "{{ mongo_image_name }}"
        recreate: yes
        pull: yes
        published_ports:
          - "27017:27017"
        env:
          - MONGO_INITDB_ROOT_USERNAME: "admin"
          - MONGO_INITDB_ROOT_PASSWORD: "password"
          
    - name: "Deploy Step: Run the mongo-express container"
      docker_container:
        name: mongodb-express
        image: "{{ mongo_express_image_name }}"
        recreate: yes
        pull: yes
        published_ports:
          - "8081:8081"
        env:
          - ME_CONFIG_MONGODB_ADMINUSERNAME: "admin"
          - ME_CONFIG_MONGODB_ADMINPASSWORD: "password"
          - ME_CONFIG_MONGODB_SERVER: "mongodb"

    - name: "Deploy Step: Run the container"
      docker_container:
        name: productApp
        image: "{{ image_name }}:1.0"
        recreate: yes
        pull: yes
        published_ports:
          - "8889:3000"
~~~



### Author
Created by @Arboulahdour

<a href="mailto:ar.boulahdour@outlook.com">E-mail me !</a>
