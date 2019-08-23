#!/bin/bash -xe
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v. 2.0, which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# This Source Code may also be made available under the following Secondary
# Licenses when the conditions for such availability set forth in the
# Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
# version 2 with the GNU Classpath Exception, which is available at
# https://www.gnu.org/software/classpath/license.html.
#
# SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0

echo "ANT_HOME=$ANT_HOME"
echo "export JAVA_HOME=$JAVA_HOME"
echo "export MAVEN_HOME=$MAVEN_HOME"
echo "export PATH=$PATH"

cd $WORKSPACE
WGET_PROPS="--progress=bar:force --no-cache"
wget $WGET_PROPS $GF_BUNDLE_URL -O ${WORKSPACE}/latest-glassfish.zip
unzip -o ${WORKSPACE}/latest-glassfish.zip -d ${WORKSPACE}




which ant
ant -version

which mvn
mvn -version

mkdir -p ${WORKSPACE}/bundles
if [ ! -z "$TCK_BUNDLE_BASE_URL" ]; then
  #use pre-built tck bundle from this location to run test
  #mkdir -p ${WORKSPACE}/bundles
  wget  --progress=bar:force --no-cache ${TCK_BUNDLE_BASE_URL}/${TCK_BUNDLE_FILE_NAME} -O ${WORKSPACE}/bundles/${TCK_BUNDLE_FILE_NAME}
  exit 0
fi

sed -i "s#^porting\.home=.*#porting.home=$WORKSPACE#g" "$WORKSPACE/build.xml"
sed -i "s#^glassfish\.home=.*#glassfish.home=$WORKSPACE/glassfish5/glassfish#g" "$WORKSPACE/build.xml"

ant -version
ant dist.sani

chmod 777 ${WORKSPACE}/dist/*.zip
cd ${WORKSPACE}/dist/
for entry in `ls cdi-tck-*.zip`; do
  date=`echo "$entry" | cut -d_ -f2`
  strippedEntry=`echo "$entry" | cut -d_ -f1`
  echo "copying ${WORKSPACE}/dist/$entry to ${WORKSPACE}/bundles/${strippedEntry}_latest.zip"
  cp ${WORKSPACE}/dist/$entry ${WORKSPACE}/bundles/${strippedEntry}.zip
  chmod 777 ${WORKSPACE}/bundles/${strippedEntry}.zip
done
