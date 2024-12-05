#!/bin/bash

cd "$(cd "$(dirname "$0")"; pwd)"

`./Font`

oldVerNumber=`grep -E "s.version *= *\".*?\"" OOGMediaPlayer.podspec | sed 's/.*s.version *= *"1.1./"/g' | sed 's/"//g'`
newVerNumber="1.1."$((oldVerNumber + 1))
txt=`cat template.txt | sed "s/17\.1\.0/$newVerNumber/g"`

git add --refresh

s=""
sep='"'
for i in `ls FontKit/Assets/fonts`; do
	s=$s$sep$i'"'
	sep=',"'
done
 
s1="subArr = []"
s2="subArr = [$s]"
echo -e "${txt//$s1/$s2}\n" > OOGMediaPlayer.podspec

taglab=`grep -E "s.version *= *\".*?\"" OOGMediaPlayer.podspec | sed 's/.*s.version.*= *//g' | sed 's/"//g'`

teststr=`git tag | grep "$taglab"`

if [[ ${#teststr} > 0 ]]; then
	git tag -d $taglab
	git push origin :refs/tags/$taglab
fi

git add .

git commit -m $taglab

git push

git tag $taglab

git push origin $taglab



specFile=$(find . -name "*.podspec")
pod repo push retro-labs-specs-ios-swift "$specFile" --allow-warnings --skip-import-validation