# Blog

The blog itself is a static html website generated using [Jekyll](https://jekyllrb.com/docs/) and hosted on AWS S3.

This portion of the repository contains the markdown files that are used to generate the content of the blog as well 
as the jekyll theme, [Klisé](https://github.com/piharpi/jekyll-klise).

## Getting Started

### To Run Locally
* Install Jekyll & Ruby (see [Jekyll Docs](https://jekyllrb.com/docs/installation/))
* execute `run-local.sh` to run the website locally. View at http://localhost:4000

### To Deploy
* Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)
* Configure AWS CLI with `aws configure` (have a user provisioned on aws already, with access to the target S3 bucket)
* Execute `configure_deployer.sh` to set the required environment variables for the `deploy-prod.sh` script.
* Run `deploy-prod.sh` to build the website and sync the contents to the target S3 bucket. The deployment script also 
attempts to invalidate CloudFront caches.

### Scripts
| Script Name | Description | 
| --- | --- |
| `run-local.sh` | Attempts to serve Jekyll locally at http://localhost:4000/ |
| `configure_deployer.sh` | Sets the required environment variables for the `deploy-prod.sh` script |
| `deploy-prod.sh` | Attempts to build Jekyll to the `_site` directory and then sync the contents to the target S3 bucket s3://www.johnsosoka.com |

## TODO
  * [ ] Add image gallery to minecraft page.
* [ ] Add Projects Page (get some projects going first)
* ~~[ ] Add [image slider](https://github.com/jekylltools/jekyll-ideal-image-slider) (or equivalent)~~
* [x] Handle embedded audio
* [x] Add Minecraft Downloads Page
* [x] Add Notes Page (Udemy Course Notes + Book Notes)


## License

The Jekyll Template used ([Klisé](klise.now.sh)) is under the: [MIT License](JEKYLL_TEMPLATE_LICENSE).

Everything else is under the [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.en.html)