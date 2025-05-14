# Jarvice Kubernetes Nested Scheduler (KNS) Applications tutorial

![GlobalProcess](img/apps_tutorial/SuperNimbix.svg)

Note: It is assumed that the user is familiar with Jarvice Push to Compute (P2C). For more information, please refer to [apps tutorial](apps_tutorial.md).

Note 2: This tutorial assumes that the user is building applications based on `appdefversion` version `2`.

## 1. Introduction

Before creating apps for the KNS scheduler, it is important to understand how KNS operates, and what exactly the KNS is.

KNS stands for Kubernetes Nested Scheduler. As the name says, KNS is a Jarvice downstream component that will spawn nested Kubernetes clusters (based on K3S)
and will deploy Kubernetes based apps inside these nested clusters, as jobs.

While traditional Jarvice downstreams are made for HPC jobs and parallel short term jobs, KNS has been designed to host long running jobs with massive scale-up capabilities. KNS is, in theory, capable of running anything that can run on a Kubernetes cluster, making it a very nice shared "sandbox".

KNS apps are docker images that contain files (mostly helm/kubectl/kustomize templates) and instructions used to deploy Kubernetes based apps like Kubeflow, ArgoCD, Kubeai, etc. While launching a new job, the KNS creates a dedicated nested K3S cluster for the job, pulls the app image from within this cluster, and uses the image's instructions to deploy the expected resources. Ingress allows users to access the nested cluster services.

## 2. The AppDef.json KNS key

KNS introduces a new key, `nested_kubernetes`, inside traditional *AppDef.json* file of Jarvice applications, at `commands` level.

A very basic hello world app would use the following AppDef.json file:

```json
{
    "name": "Hello World",
    "description": "Hello world app for KNS.",
    "author": "oxedions",
    "licensed": false,
    "appdefversion": 2,
    "appkind": "kns",
    "classifications": [
        "Uncategorized"
    ],
    "machines": [
        "*"
    ],
    "vault-types": [
        "FILE",
        "BLOCK",
        "BLOCK_ARRAY",
        "OBJECT"
    ],
    "commands": {
        "Hello": {
            "path": "/usr/bin/true",
            "name": "Start nested http server",
            "description": "Start a nested http server for testing and to say hello world.",
            "parameters": {},
            "nested_kubernetes": {
                "targets": [
                    {
                        "service_name": "web",
                        "service_port": 8080,
                        "service_namespace": "default"
                    }
                ],
                "templates": [
                    {
                        "name": "google-sample",
                        "type": "kubectl",
                        "path": "google-sample.yml"
                    }
                ]
            }
        }
    },
    "image": {
        "type": "image/png",
        "data": ""
    }
}
```

Let's examine this file step by step. We will only focus on the commands part, everything else is the same astraditional Jarvice apps.

```json
    "commands": {
        "Hello": {
```

* `commands` is a dictionary, so you can add any app entry points as needed. This can be useful for creating an all-in-one app image for example.
* `Hello` is the name of the current entry point for the app.

```json
        "Hello": {
            "path": "/usr/bin/true",
            "name": "Start nested http server",
            "description": "Start a nested http server for testing and to say hello world.",
            "parameters": {},
```

For KNS jobs, `path` and `parameters` are not used, but need to be present for the app to be usable by Jarvice upstream component.
`path` should be set to `/usr/bin/true` and `parameters` should be left as an empty dictionary.

`name` and `description` will display as before some details about this entry point, for users to be able to choose between multiple if they exist.

```json
            "nested_kubernetes": {
                "targets": [
                    {
                        "service_name": "web",
                        "service_port": 8080,
                        "service_namespace": "default"
                    }
                ],
                "templates": [
                    {
                        "name": "google-sample",
                        "type": "kubectl",
                        "path": "google-sample.yml"
                    }
                ]
            }
```

`nested_kubernetes` is the new key that allows to define inside it all needed elements for a Kubernetes based app.
Let's see each partsof this new dictionary.

### 2.1. General parameters

```json
            "nested_kubernetes": {
                "kubernetes_version": "",
```

* `kubernetes_version` (optional) allows to specify the Kubernetes version to be used for the K3S nested cluster. Note that only major version are supported, like `v1.30`. Minor version is automatically chosen depending on the KNS tool version.

### 2.2. Ingress parameters

Ingress parameters allow connecting the app to the external world, by giving the final user the URL to reach the app portal/entry point/API/etc. You need to specify here the target service.

```json
                "targets": [
                    {
                        "service_name": "web",
                        "service_port": 8080,
                        "service_namespace": "default"
                    }
                ],
```

`targets` list is then used to define ingresses to spawn.
For now, KNS will only consider the first item on the list. This limitation might be removed in later versions.

The following parameters are to be set for each ingress target:

* `service_name`: name of the service to link ingress to.
* `service_port`: port of the service to link ingress to.
* `service_namespace`: namespace where the service to link ingress to is.

### 2.3. Templates parameters

#### 2.3.1. Global settings

```json
                "templates_settings": {
                    "global_retry": 20,
                    "global_retry_sleep": 15
                },
```

Templates are provided as a list, named `templates`, which will be executed in an ordered manner.

While each item of the list can set its own parameters, the following global parameters are available, which apply to all items of the template list:

* `global_retry`: how many retries to do if executing the item failed. For example, if the `kubectl apply` of the template fails, it will be retried. This is useful when a step needs another previous one to be completed to succeed (resources running).
* `global_retry_sleep`: how many seconds should we wait between each retry.

#### 2.3.2. Templates

```json
                "templates": [
                    {
                        "name": "google-sample",
                        "type": "kubectl",
                        "path": "google-sample.yml"
                    }
                ]
```

The `templates` list allows execution of instructions in an orderly manner and applies templates to deploy the app into the nested scheduler.

Note that before executing templates, the KNS will pull and extract the app image. All files inside the `/templates` folder of the image will be extracted and execution will take place **inside** this extracted folder.

For example, in our current example, hello world, the dockerfile contains:

```dockerfile
RUN mkdir /templates
COPY google-sample.yml /templates/google-sample.yml
```

For each step, a `name` parameter must be set. This is only for convenience and ease of reading logs.

It is also possible to fine define retry and sleep between retries:

```json
                "templates": [
                    {
                        "name": "google-sample",
                        "type": "kubectl",
                        "path": "google-sample.yml",
                        "retry": 10,
                        "retry_sleep": 30
                    }
                ]
```

For this item, `retry` will precedence `global_retry` if set, and `retry_sleep` will precedence `global_retry_sleep`.

There are then 3 types of actions available:

##### 2.3.2.1. kubectl type

Kubectl will execute the following command:

```
/usr/bin/kubectl apply -f path/to/template.yml
```

If `type` is set to `kubectl`, then a `path` must be provided, relative to the root of `/templates` folder of the app image.
In our example, since our `google-sample.yml` file is at `/templates/google-sample.yml` into our app image, `path` will simply be `google-sample.yml`.

Note that the kubectl type also allows to use a URL as a template, to fetch a remote template (with all the risks that it implies!).
To do so, specify a special key `format` to `url`, and provide the URL inside the `path` key. For example, to deploy Argo CD:

```json
                "templates": [
                    {
                        "name": "allinone",
                        "type": "kubectl",
                        "path": "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
                        "format": "url"
                    }
                ]
```

Again, YOU MUST trust the owner of the remote template to use this feature.

##### 2.3.2.2. kustomize type

Kustomize will execute the following command:

```
/usr/bin/kubectl apply -k path/to/folder/
```

And so allows using the equivalent of the kustomize command (that was merged into kubectl command) on a folder of dynamic templates.

As for kubectl type, you need to provide a `path` value, relative to the `/templates` folder of the app image.

##### 2.3.2.3. custom type

Custom allows to execute arbitrary scripts instead of using a specific command to apply templates.
It is also possible to use custom type to deploy helm based applications.

When using custom, a `cmd` key must be set, and it should contain the script to be executed, encoded in base64 format.

For example, to deploy a basic KubeAI, which uses helm to deploy:

```json
                "templates": [
                    {
                        "name": "helmdeploy",
                        "type": "custom",
                        "cmd": "IyEvYmluL2Jhc2gKIwoKc2V0IC14CgpnaXQgY2xvbmUgaHR0cHM6Ly9naXRodWIuY29tL3N1YnN0cmF0dXNhaS9rdWJlYWkgJiYgY2Qga3ViZWFpCgpjYXQgPDxFT0YgPiBoZWxtLXZhbHVlcy55YW1sCm1vZGVsczoKICBjYXRhbG9nOgogICAgZ2VtbWEyLTJiLWNwdToKICAgICAgZW5hYmxlZDogdHJ1ZQogICAgICBtaW5SZXBsaWNhczogMQogICAgcXdlbjItNTAwbS1jcHU6CiAgICAgIGVuYWJsZWQ6IHRydWUKICAgIG5vbWljLWVtYmVkLXRleHQtY3B1OgogICAgICBlbmFibGVkOiB0cnVlCkVPRgoKaGVsbSB1cGdyYWRlIC0taW5zdGFsbCBrdWJlYWkgLi9jaGFydHMva3ViZWFpIFwKICAgIC1mIC4vaGVsbS12YWx1ZXMueWFtbCBcCiAgICAtLXdhaXQgLS10aW1lb3V0IDEwbQoK"
                    }
                ]
```

The `cmd` content is the result of running this script:

```bash
#!/bin/bash
#

set -x

git clone https://github.com/substratusai/kubeai && cd kubeai

cat <<EOF > helm-values.yaml
models:
  catalog:
    gemma2-2b-cpu:
      enabled: true
      minReplicas: 1
    qwen2-500m-cpu:
      enabled: true
    nomic-embed-text-cpu:
      enabled: true
EOF

helm upgrade --install kubeai ./charts/kubeai \
    -f ./helm-values.yaml \
    --wait --timeout 10m
```

That was encoded this way:

```
cat myscript.sh | base64 -w 0
```

Encoding scripts prevents any kind of evaluation issues.

### 2.4. AppKind

When creating a KNS application, it is possible and recommended to add the appkind value to the appdef.

By default, if not set, the appkind will be defined to "k8s". For KNS applications, appkind should be set to "kns" instead.

This key allows a machines filtering mechanism when selecting machine for a job in the portal interface.
If not set, all machines will display, leading to possible missusage and crash of job.
