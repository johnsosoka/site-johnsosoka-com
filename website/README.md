# Website

This section of the repository houses the jekyll theme + source content for blog posts & 
pages. You can find the original markup docs mostly in the `pages` and `_posts` directories.

I have built customizations on top of the template Klisé which can be found [here](https://github.com/piharpi/jekyll-klise)

### Customizations

#### Layouts

* Created lore layout. It's just like a page layout but includes a GO BACK button (text of button controlled in yaml)
  * The idea of lore would be little pages/offshoots explaining something. The example that prompted this to be made is the snippet on the braille book dad got me.

* Set up embed-audio.html. Example usage:
```html
{% include embed-audio.html src="https://files.johnsosoka.com/music/the-concept/through-times-eyes-ep/What-a-Time-Version-2.mp3" %}
```

### Scripts

`run-local.sh` will attempt to serve jekyll locally at http://localhost:4000/

`deploy-prod` will attempt to build jekyll to the `_site` dir and then sync the contents to the target S3 bucket s3://www.johnsosoka.com


## TODO

* [ ] Add [image slider](https://github.com/jekylltools/jekyll-ideal-image-slider) (or equivalent)
  * [ ] Add image gallery to minecraft page.
* [ ] Add Projects Page (get some projects going first)
* [x] Handle embedded audio
* [x] Add Minecraft Downloads Page
* [x] Add Notes Page (Udemy Course Notes + Book Notes)


## License

The Jekyll Template used ([Klisé](klise.now.sh)) is under the: [MIT License](JEKYLL_TEMPLATE_LICENSE).

Everything else is under the [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.en.html)