# blog.haskell-ita.it

## How to Update the Website

### Initial Setup

Clone this repo locally.

Compile the application with Nix or Stack. 

#### Nix Instructions

Execute

    ./generate-nix-project.sh
    nix-shell ./shell.nix
    cabal build
    ./dist/build/site/site clean
    ./dist/build/site/site build

#### Stack Instructions

TODO complete

### Website Configuration

The file `site.hs` contains the rules used from Hakyll for generating the website. Every time you change them:

* recomplie the application
* clean the website with `site clean`

### Website Preview

Execute

    site watch

for a live preview of the website. In case of change of files, the preview is updated.

### Adding a Post

Add posts inside `posts/` directory, in the proper subdirector, playing the role of category.

Use already defined posts as example. Hakyll uses Pandoc that is very powerful and many different type of files are accepted.

#### Teaser

It is convenient to have an excerpt of a post displayed on the index page along with a “Read more…” link to encourage your readers to read the rest of the post. For doing this put the teaser symbol where the excerpt end. 

    <!--more-->

In case of Literate Haskell Code use instead

    <div></div><!--more-->

for bypassing the byrding style `>` character.

### Website Update

Execute

    site build

for updating the `_site/` directory. In case of big changes it is better a

    site clean
    site build

Then make a Git commit, and push to the remote repo.

    git status
    git add <missing-files>
    git commit -a -m "<some-message>"
    git push

The hosting server will make a pull, and publish the content of `_site/` directory. All other content will be not be published. 

### Known Problems

If you miss the tag `date`, Hakyll generates a not clear error message like:

     [ERROR] Missing field $posts$ in context for item 3/index.html

## Project Roadmap (TODO)

### Full Site Design

Il sito deve fare da:

* home page
* blog
* wiki/knowledge-base

TODO mettere i CONTACTS con tutti gli altri siti che formano la community
TODO salvo in un branch a parte di haskell-ita dato che fa parte effettivamente di un sito diverso

### Initial Release

TODO se impicciolisco la finestra, il bottone di bootstrap non lavora correttamente 

TODO usare un formato grafice dei link migliore: azzurro o qualcosa del genere/standard

TODO togliere sezione su INFRASTRUCTURE dato che bastano i links ai siti

TODO essere sicuri di usare il nero per il blog

TODO i sottotitoli nei blog devono avere dimensioni minori dei titoli del blog

TODO aggiungere siti in basso social appropiati e anche altri indicatori

TODO aggiungere in basso che e\` stato costrito con Hakyll

TODO includere link al repository con il sito

TODO usare classe bootstrap appropiata per le immagini

TODO aggiungere link anche nel titolo del post

TODO rimuovere immagine a SX

TODO spostare contenuto blog a SX

TODO test haskell-ita piccolo

TODO aggiungere logo

TODO attivare CSS nei posts del blog

TODO remove dynamic libraries when it is all correct

TODO prima sistemo la struttura poi la grafica/template

TODO se scelgo un TAG:
* mostro il TAG scelto usando un colore diverso, in stile TAB
* mostro solo i post del TAG senza la FRONT-PAGE

TODO nel footer descrivere chi siamo

TODO provare a fare subscribe ai FEEDS quando ho installato 

TODO chiedere se puo` diventare la pagina standard di Haskell invece che il blog

## Automatic Update of the WebSite

TODO create a web-hook on GitHub

TODO the web server receive the hook, make git pull of the repo, and then make a site build

TODO daily the web server execute also a site clean and regeneration, in order to manage the big changes in the structure of the code of the site

