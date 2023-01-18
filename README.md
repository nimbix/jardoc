# jardoc
Public JARVICE documentation

# Local test the documentation

From the toplevel directory of this repo

```
pip install -r requirements.txt
mkdocs serve
```
Local changes to markdown files automatically reload in test server.

# Generate PDF documentation

* Uncomment the `with-pdf` part from the `mkdocs.yml` configuration file.

```
plugins:
# - with-pdf:
    #     author: Nimbix
    #     copyright: '@ 2022 Nimbix'
    #     cover: true
    #     back_cover: false
    #     cover_title: Jarvice
    #     cover_subtitle: documentation
    #     toc_level: 2
    #     output_path: pdf/jarvice.pdf
```

* Install the following packages with your package manager

```
libpangoft2-1.0-0
libpango-1.0-0
```

* From the toplevel directory of this repo

```
pip install -r requirements.txt
mkdocs serve
```
Local changes to markdown files automatically reload in test server.


# Deployment
This documentation set automatically deploys in https://jarvice.readthedocs.io/

