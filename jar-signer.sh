#!/usr/bin/env bash

set -e

GROUP="$1"
ARTIFACT="$2"
VERSION="$3"

repo_base=$(mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout)
repo_path=$repo_base/$(echo "$GROUP" | tr . /)/$ARTIFACT/$VERSION

mvn dependency:get -DremoteRepositories=http://repo1.maven.org/maven2/ \
                   -DgroupId="$GROUP" -DartifactId="$ARTIFACT" -Dversion="$VERSION" \
                   -Dtransitive=false

file_name="$ARTIFACT-$VERSION.jar"

rm -rf work
mkdir work
cd work || exit
cp "$repo_path"/"$file_name" .

mkdir -p "META-INF/maven/$GROUP/$ARTIFACT"
cp "$repo_path/$ARTIFACT-$VERSION.pom" "META-INF/maven/$GROUP/$ARTIFACT/pom.xml"
cat << EOF > "META-INF/maven/$GROUP/$ARTIFACT/pom.properties"
artifactId=$ARTIFACT
groupId=$GROUP
version=$VERSION
EOF
jar -uf "$file_name" "META-INF/maven/$GROUP/$ARTIFACT/pom.xml" "META-INF/maven/$GROUP/$ARTIFACT/pom.properties"


for file in $(jar -tf "$file_name" | grep -E '\.(jnilib|dylib)$'); do
  jar -xf "$file_name" "$file"
  codesign -s "$DEVELOPER_ID" -v -f "$file"
  jar -uf "$file_name" "$file"
done

fury push "$file_name" --public

