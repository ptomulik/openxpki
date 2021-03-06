Introduction
============

This manual describes the installation and use of the OpenXPKI software, an Open Source trustcenter solution written by The OpenXPKI Project. 

The intended audience are CA administrators and operators. We assume that readers are familiar working on a Unix shell and have enough background knowledge about Public Key Infrastructures to understand the relevant terms.

The OpenXPKI manual is split into the following sections:

* The introduction, which you are reading right now. Following this abstract, you will learn more about where to get the software, where to get help. Furthermore, a high-level overview of the system design and some key concepts will be presented.
* The :ref:`quickstart` Quickstart chapter lays the emphasis on getting a minimal Certificate Authority (CA) without any bells and whistles running. Reference to further configuration options is provided inline, so that you know where to look if you want to configure more advanced features. Please note that setting up a working CA is a complex task and thus the ''quick'' in "quick start" may be a bit euphemistic.
* Following the quick start, more information on the ''[[Manual/Workflow_Engine|workflow engine]]'' and the pre-defined workflows is given. This section also provides help if you are looking for information on implementing your own custom workflow.
* The last chapter is called ''[[Manual/Reference|Reference]]'' and provides just that - information on all of the various configuration options concerning databases, cryptographic settings, workflows and access control, manuals for the various administrative and deployment tools as well as some information on where to look if something goes wrong.


Key features
============

Assuming this is your first contact with OpenXPKI here is a quick summary of what it is and what it is capable of.

OpenXPKI aims to be an enterprise-scale Public Key Infrastructure (PKI) solution, supporting well established infrastructure components like RDBMS and Hardware Security Modules (HSMs). It started as the successor of OpenCA,
and builds on the experience gained while developing it as well as on our experience in large public key infrastructures.

* *CA rollover:* "Normal" trust center software usually does not account for the installment of a new CA certificate, thus if the CA certificate becomes invalid, a complete re-deployment has to be undertaken. OpenXPKI solves this problem by automatically deciding which CA certificate to use at a certain point in time.
* *Support for multiple so-called PKI realms:* Different CA instances can be run in a single installation without any interaction between them, so one machine can be used for different CAs.
* *Private key support both in hardware and software:* OpenXPKI has support for professional Hardware Security Modules such as the nCipher nShield or the Chrysalis-ITS Luna CA modules. If such modules are not available, access to a key can be protected by using a threshold secret sharing algorithm.
* *Professional database support:* The user can choose from a range of database backends, including commercial ones such as Oracle or DB2, which are typically used in enterprise scenarios.
* *Many different interfaces to the server:* Currently, one can access the CA server using a web-interface (which also allows for client-side request generation using SPKAC).  Embedded devices such as routers can also use the Simple Certificate Enrollment Protocol (SCEP) to talk to the server and apply for certificates - including automatic renewal.
* *Workflow Engine:* OpenXPKI aims to be extremly customizable by allowing the definition of workflows for any process you can think of in the PKI area. Typical workflows such as editing and approving certificate signing requests, certificate and CRL issuance are already implemented. Implementing your own idea is normally pretty easy by defining a workflow in XML and (maybe) implementing a few lines in Perl. The workflow engine also comes with configuration versioning support &ndash; if you change the configuration while a workflow is still running, the workflow will still use the configuration it started with, while new workflows will be created using the new configuration. This allows for on-the-fly configuration changes that do not wreak havoc with the currently running system.
* *I18N:* Localization of the application and interfaces is easily possible and OpenXPKI can of course deal with the whole range of Unicode characters in certificates.
* *Self-Service application for smartcard/token personalization:* A web application which allows a user to easily create and install certificates to a smartcard is available.
* *Template-based certificate details:* Contrary to the typical CA system, your users do not need to know about how you would like the subject to look like - you can just ask them for the information they know (for example a hostname and port) and OpenXPKI will create the corresponding subject and subjectAlternativeNames for you. Regular expression support allows you to enforce certificate naming conventions easily.
* *Better support using [http://www.bestpractical.com/rt/ Request Tracker]:* A heavy load of certificate requests that need additional communication with the requesters can be easily dealt with using the notification interface. Currently only Request Tracker, an open source ticketing system is supported, but the interface is implemented in a general way so that adding other ticket systems is pretty easy. Users can thus automatically receive e-mails once a certificate is issued for example.

