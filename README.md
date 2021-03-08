
First - quick Getting Started for Development! (more about AbeliiApp below...)

First you have to have already setup the abelii language environment, see
https://gitlab.com/bitsii/abelii (Getting Started in Readme.md) for that

then, from the directory containing "abelii" (where you cloned it), clone abeliiApp
(from your shell / on MSWin from the git shell you installed)

git clone https://gitlab.com/bitsii/abeliiApp
cd abeliiApp
./scripts/devprep.sh

that's it - Abelii as such is just a source and dependencies library project
to actually use it checkout and build a project that uses it (here's a couple):

https://gitlab.com/edgii/BNote
https://gitlab.com/edgii/BBridge

as you build these apps all of the artifacts and the runtime environment
are in a directory called apprun in the same parent as abeliiApp and the 
BNote/BBRidge/etc areas.   Inside apprun is an App dir, inside App are the app
specific executable code (BBridge, etc) and the artifacts (html, etc).
Under data are the key value db's and their data, as well as other
configuration and data.  Under Home are the account home directories.  

End of Getting Started for Development!

The Abelii application infrastructure is a framework written in the [Abelii](https://gitlab.com/bitsii/abelii) programming language licensed under the [BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause) open source license which enables the authoring of web and hybrid applications that target a wide range of environments - Linux, Windows, or Mac desktop applications using the built-in browser, Android and IOS mobile applications using the built-in webviews, and a hosted application as a website.  Includes web user interface infrastructure and key/value database support, web service / http(s) client support, as well as cross platform support for io, file, and process management.  See the [Bitsii](https://gitlab.com/bitsii/Bitsii/-/wikis/home) project for some examples.
