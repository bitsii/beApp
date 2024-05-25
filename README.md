
Beysant App is a framework written in the [Beysant](https://gitlab.com/bitsii/beBase) programming language licensed under the [BSD-2-Clause](https://opensource.org/licenses/BSD-2-Clause) open source license which enables the authoring of web and hybrid applications that target a wide range of environments - Linux, Windows, or Mac desktop applications using the built-in browser, Android and IOS mobile applications using the built-in webviews, and a hosted application as a website.  Includes web user interface infrastructure and key/value database support, web service / http(s) client support, as well as cross platform support for io, file, and process management.  See the [Bitsii](https://gitlab.com/bitsii/Bitsii/-/wikis/home) project for some examples.

Quick Getting Started for Development!

First you have to have already setup the Beysant language environment, see
https://gitlab.com/bitsii/beBase (Getting Started in Readme.md) for that  (the Beysant
  java environment should be enough)

then, from the directory containing "beBase" (where you cloned it, not the beBase 
  directory itself, the one above it), clone beApp
(from your shell / on MSWin from the git shell you installed)

git clone https://gitlab.com/bitsii/beApp
cd beApp
./scripts/devprep.sh

that's it - beApp as such is just a source and dependencies library project
to actually use it checkout and build a project that uses it (here's a couple):

https://gitlab.com/bitsii/BBridge

https://gitlab.com/bitsii/CasCon

as you build these apps all of the artifacts and the runtime environment
are in a directory called apprun in the same parent as beApp and the 
BNote/BBRidge/etc areas.   Inside apprun is an App dir, inside App are the app
specific executable code (BBridge, etc) and the artifacts (html, etc).
Under data are the key value db's and their data, as well as other
configuration and data.  Under Home are the account home directories.  

End of Getting Started for Development!

The official list of Beysant App Authors:

Craig Welch <bitsiiway@gmail.com>
