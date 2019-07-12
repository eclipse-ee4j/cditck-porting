/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0, which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the
 * Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
 * version 2 with the GNU Classpath Exception, which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 */

env.label = "cdi-tck-ci-pod-${UUID.randomUUID().toString()}"
pipeline {
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  agent {
    kubernetes {
      label "${env.label}"
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
spec:
  hostAliases:
  - ip: "127.0.0.1"
    hostnames:
    - "localhost.localdomain"
  containers:
  - name: cdi-tck-ci
    image: anajosep/cts-base:0.1
    command:
    - cat
    tty: true
    imagePullPolicy: Always
    env:
      - name: JAVA_TOOL_OPTIONS
        value: -Xmx2G
    resources:
      limits:
        memory: "6Gi"
        cpu: "1.25"
"""
    }
  }
  parameters {
    string(name: 'GF_BUNDLE_URL', 
           defaultValue: 'https://download.eclipse.org/ee4j/jakartaee-tck/8.0.1/nightly/glassfish.zip',
           description: 'URL required for downloading GlassFish Full/Web profile bundle' )
    choice(name: 'PROFILE', choices: 'FULL\nWEB', 
           description: 'Profile to be used for running CTS either web/full' )
	string(name: 'TCK_BUNDLE_BASE_URL',
           defaultValue: '',
           description: 'Base URL required for downloading prebuilt binary TCK Bundle from a hosted location' )
    string(name: 'TCK_BUNDLE_FILE_NAME', 
           defaultValue: 'cdi-tck-glassfish-porting-2.0_latest.zip', 
	   description: 'Name of bundle file to be appended to the base url' )
  }
  environment {
    ANT_HOME = "/usr/share/ant"
    MAVEN_HOME = "/usr/share/maven"
    ANT_OPTS = "-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalSchema=all -Djavax.xml.accessExternalDTD=file,http" 
  }
  stages {
    stage('cdi-tck-build') {
      steps {
        container('cdi-tck-ci') {
          sh """
            env
            bash -x ${WORKSPACE}/docker/build_cditck.sh
          """
          archiveArtifacts artifacts: 'bundles/*.zip'
        }
      }
    }
  
    stage('cdi-tck-run') {
      steps {
        container('cdi-tck-ci') {
          sh """
            env
            bash -x ${WORKSPACE}/docker/run_cditck.sh
          """
          archiveArtifacts artifacts: "cdi-tck-results.tar.gz,cdi-tck-report/**/*.xml,cdi-tck-report/**/*.html"
          junit testResults: 'cdi-tck-report/**/*.xml', allowEmptyResults: true
        }
      }
    }
  }
}
