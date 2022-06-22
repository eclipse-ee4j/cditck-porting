#!/bin/bash -xe
#
# Copyright (c) 2022, 2022 Contributors to the Eclipse Foundation
# Copyright (c) 2018, 2022 Oracle and/or its affiliates. All rights reserved.
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

VER=4.0.0

if [ -z "$GF_TOPLEVEL_DIR" ]; then
  export GF_TOPLEVEL_DIR=glassfish7
fi


if [[ "$JDK" == "JDK17" || "$JDK" == "jdk17" ]];then
  export JAVA_HOME=${JDK17_HOME}
fi
export PATH=$JAVA_HOME/bin:$PATH

#Install Glassfish
echo "Download and install GlassFish ..."
wget --progress=bar:force --no-cache $GF_BUNDLE_URL -O ${WORKSPACE}/latest-glassfish.zip
unzip -q -o ${WORKSPACE}/latest-glassfish.zip -d ${WORKSPACE}

if [ -z "${CDI_TCK_VERSION}" ]; then
  CDI_TCK_VERSION=4.0.5
fi

if [ -z "${CDI_TCK_BUNDLE_URL}" ]; then
  CDI_TCK_BUNDLE_URL=https://download.eclipse.org/ee4j/cdi/4.0/cdi-tck-4.0.5-dist.zip
fi

#Install CDI TCK dist
echo "Download and unzip CDI TCK dist ..."
wget --progress=bar:force --no-cache $CDI_TCK_BUNDLE_URL -O latest-cdi-tck-dist.zip
unzip -q -o ${WORKSPACE}/latest-cdi-tck-dist.zip -d ${WORKSPACE}/

GROUP_ID=jakarta.enterprise
CDI_TCK_DIST=cdi-tck-${CDI_TCK_VERSION}

cd ${CDI_TCK_DIST}/artifacts
mvn --global-settings "${WORKSPACE}/settings.xml" install

export PATH=$JAVA_HOME/bin:$PATH

which java
java -version

REPORT=${WORKSPACE}/cdi-tck-report

mkdir -p ${REPORT}/cdi-$VER-sig
mkdir -p ${REPORT}/cdi-$VER

#Edit Glassfish Security policy
cat ${WORKSPACE}/docker/CDI.policy >> ${WORKSPACE}/${GF_TOPLEVEL_DIR}/glassfish/domains/domain1/config/server.policy

#Run Tests
export MAVEN_OPTS="-Duser.home=$HOME $MAVEN_OPTS"
cd ${WORKSPACE}/glassfish-tck-runner
mvn --global-settings ${WORKSPACE}/settings.xml -Pcdi-signature-test process-test-sources
mvn --global-settings ${WORKSPACE}/settings.xml -U clean dependency:tree verify

#Generate Reports
echo "<pre>" > ${REPORT}/cdi-$VER-sig/report.html
cat ${WORKSPACE}/glassfish-tck-runner/target/cdi-sig-report.txt >> $REPORT/cdi-$VER-sig/report.html
echo "</pre>" >> $REPORT/cdi-$VER-sig/report.html
cp $REPORT/cdi-$VER-sig/report.html $REPORT/cdi-$VER-sig/index.html

# Copy the test reports to the report directory
cp -R ${WORKSPACE}/glassfish-tck-runner/target/surefire-reports/* ${REPORT}/cdi-${VER}
cp -R ${WORKSPACE}/glassfish-tck-runner/target/failsafe-reports/* ${REPORT}/cdi-${VER}
if [[ -f ${REPORT}/cdi-$VER/test-report.html ]];then
  cp ${REPORT}/cdi-$VER/test-report.html ${REPORT}/cdi-${VER}/report.html
fi

mv ${REPORT}/cdi-$VER/TEST-TestSuite.xml  ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
sed -i'' -e 's/name=\"TestSuite\"/name="cditck-4.0"/g' ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
# Create Junit formated file for sigtests
echo '<?xml version="1.0" encoding="UTF-8" ?>' > $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testsuite tests="TOTAL" failures="FAILED" name="cdi-4.0-sig" time="0" errors="0" skipped="0">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testcase classname="CDISigTest" name="cdiSigTest" time="0.2">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  <system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
cat ${WORKSPACE}/glassfish-tck-runner/target/cdi-sig-report.txt >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  </system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testcase>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testsuite>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml

# Fill appropriate test counts
if [ -f "$REPORT/cdi-$VER-sig/report.html" ]; then
  if grep -q STATUS:Passed "$REPORT/cdi-$VER-sig/report.html"; then
    sed -i'' -e 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i'' -e 's/failures=\"FAILED\"/failures="0"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  else 
    sed -i'' -e 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i'' -e 's/failures=\"FAILED\"/failures="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  fi
fi

tar zcvf ${WORKSPACE}/cdi-tck-results.tar.gz ${REPORT} ${WORK} ${WORKSPACE}/${GF_TOPLEVEL_DIR}/glassfish/domains/domain1/logs/
