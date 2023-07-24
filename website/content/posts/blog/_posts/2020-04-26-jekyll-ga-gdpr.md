---
layout: post
title: GDPR Compliance with Jekyll & Google Analytics
category: blog
subtitle: Integrating the official Jekyll cookie-consent solution with a 3rd party theme's OOTB Google Analytics implementation.
image: /img/gdpr/cc-icon.png
tags: jekyll theme analytics ga google analytics
---
![gdpr](https://media.johnsosoka.com/old/img/blog/gdpr/gdpr-jekyll-ga.png)

I'm currently in the process of setting up the infrastructure needed to run my site and at some point in the future 
I want to enable Google Analytics (GA) to get some usage statistics. _Why Google Analytics?_ 
Well, I think it would be fun to watch my annual visitors increase (from 0 to 3 or even as much as 5) as more and more search crawler 
bots find and index my site...

But, it got me thinking that since GA does some work under the hood to track visitors on my site, I should probably set up a mechanism to be 
[GDPR compliant](https://gdpr-info.eu/) and only track visitors if they consent to be tracked.

# Cookie Consent Collection

The bulk of the work for cookie-consent collection has already been done by the Jekyll crew, so my Sunday project began by
following [the official Jekyll doc](https://jekyllcodex.org/without-plugin/cookie-consent/) on the collection of cookie 
consent. The Jekyll team explains how their code works:
>The code inserts a cookie banner at the bottom of the screen. When you click ‘Approve’ it creates a cookie that is valid for 31 days. Each page load the code checks for the existence of this cookie. If it exists (and the value is ‘true’), the blocked scripts are loaded. The blocked scripts can be found in the includes in the code below. You can easily replace these includes with your own.

and the snippet:
{% raw  %}
```javascript
if(readCookie('cookie-notice-dismissed')=='true') {
    {% include ga.js %}
    {% include chatbutton.js %}
}
```
{% endraw %}

I went ahead and copied the [cookie-consent.html](https://raw.githubusercontent.com/jhvanderschee/jekyllcodex/gh-pages/_includes/cookie-consent.html)
into my `_includes`  directory and then tried to find a suitable location to include it.

## Working with beautiful-jekyll
I should call out that the theme I'm using is [beautiful-jekyll](https://deanattali.com/beautiful-jekyll/) so the specifics of the information here forward are
unique to that theme, but the principles here should be applicable to other Jekyll themes--Particularly themes with out
of the box support for google analytics. While I'm calling things out, I should also call out that I am seriously **not** a front-end
engineer.

I found a document that looked like a layout document in `_layouts/base.html` and added the cookie-consent include beneath the footer includes shown below:

{% raw %}
```
  <body>
    {% include gtm_body.html %}
    {% include nav.html %}
    {{ content }}
    {% include footer.html %}
    {% include footer-scripts.html %}
    {% include cookie-consent.html %} 
  </body>
```
{% endraw %}

Once I had that in place, I went ahead and fired up my local Jekyll instance to see if I was able to get a cookie-consent banner. You may have been able 
to guess that I encountered the following error:

```shell
Configuration file: /mnt/g/code/johnsosoka-com/_config.yml
            Source: /mnt/g/code/johnsosoka-com
       Destination: /mnt/g/code/johnsosoka-com/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
  Liquid Exception: Could not locate the included file 'ga.js' in any of ["/mnt/g/code/johnsosoka-com/_includes", "/var/lib/gems/2.3.0/gems/jekyll-theme-primer-0.5.4/_includes"]. Ensure it exists in one of those directories and is not a symlink as those are not allowed in safe mode. in /_layouts/base.html
```

It took me a minute to figure it out--Of course I'm getting this error, I didn't update the example includes in the `_cookie-consent.html` file.
I just want to see if the banner is visible, so to get unstuck I comment out the `ga.js` and `chatbutton.js` includes and start my local
site again.

{{ file.cookie-consent-banner.png }}

![consent banner](https://media.johnsosoka.com/old/img/blog/gdpr/cookie-consent-banner.png){: .center-block :}

I see the banner below the footer, which is what I was hoping for. Next up I will test the script by clicking approve. When I click that
button, I am expecting a cookie named `cookie-notice-dismissed` to be created with the value `true`. I used chrome dev tools to quickly reveal:

![cookie](https://media.johnsosoka.com/old/img/blog/gdpr/cookie-set.png){: .center-block :}

Wonderful! I now have the banner displaying and the cookie being properly set. When I load other pages after accepting the cookie consent policy the banner no longer
displays which is perfect. Now all that remains is to:

* Wire up OOTB GA scripts to the Cookie Consent Scripts
* Create a cookie consent landing page
* Update the `More Info` button's href

## Conditionally Loading Google Analytics

The theme beautiful-jekyll already comes with out of the box support for Google Analytics which we need to tweak so that Google Analytics is only loaded if the cookie-consent 
collection policy has been accepted. I know that beautiful-jekyll has OOTB GA support, but I'm not sure _how_ it works. I began my journey by looking at the contents of my `_include` directory 
which yields:

```shell
total 48
drwxrwxrwx 1 john john 4096 Apr 26 09:46 ./
drwxrwxrwx 1 john john 4096 Apr 24 00:43 ../
-rwxrwxrwx 1 john john  182 Apr 21 17:41 comments.html*
-rwxrwxrwx 1 john john 1964 Apr 26 09:33 cookie-consent.html*
-rwxrwxrwx 1 john john  884 Apr 21 17:41 disqus.html*
-rwxrwxrwx 1 john john  302 Apr 21 17:41 ext-css.html*
-rwxrwxrwx 1 john john  271 Apr 21 17:41 ext-js.html*
-rwxrwxrwx 1 john john  712 Apr 21 17:41 fb-comment.html*
-rwxrwxrwx 1 john john 2051 Apr 21 17:41 footer.html*
-rwxrwxrwx 1 john john  370 Apr 21 17:41 footer-minimal.html*
-rwxrwxrwx 1 john john  847 Apr 21 17:41 footer-scripts.html*
-rwxrwxrwx 1 john john  615 Apr 21 17:41 google_analytics.html*
-rwxrwxrwx 1 john john  361 Apr 21 17:41 gtag.html*
-rwxrwxrwx 1 john john  292 Apr 21 17:41 gtm_body.html*
-rwxrwxrwx 1 john john  480 Apr 21 17:41 gtm_head.html*
-rwxrwxrwx 1 john john 2370 Apr 21 17:41 header.html*
-rwxrwxrwx 1 john john 4417 Apr 21 17:41 head.html*
-rwxrwxrwx 1 john john  701 Apr 21 17:41 matomo.html*
-rwxrwxrwx 1 john john 2063 Apr 21 17:41 nav.html*
-rwxrwxrwx 1 john john 1537 Apr 21 17:41 social-share.html*
-rwxrwxrwx 1 john john 1183 Apr 21 17:41 staticman-comment.html*
-rwxrwxrwx 1 john john 5559 Apr 21 17:41 staticman-comments.html*
-rwxrwxrwx 1 john john  373 Apr 21 17:41 utterances-comment.html*
```

I noticed `google_analytics.html` and decided to peak at the contents which were:

{% raw %}
```javascript
{% if site.google_analytics %}
<!-- Google Analytics -->
<script>
    (function (i, s, o, g, r, a, m) {
        i['Google AnalyticsObject'] = r; i[r] = i[r] || function () {
            (i[r].q = i[r].q || []).push(arguments)
        }, i[r].l = 1 * new Date(); a = s.createElement(o),
            m = s.getElementsByTagName(o)[0]; a.async = 1; a.src = g; m.parentNode.insertBefore(a, m)
    })(window, document, 'script', 'https://www.google-analytics.com/analytics.js', 'ga');
    ga('create', '{{ site.google_analytics }}', 'auto');
    ga('send', 'pageview');
</script>
<!-- End Google Analytics -->
{% endif %}
```
{% endraw %}

So, the Google Analytics script is already being conditionally written to the document when the site is generated based off of conditions
that need to be satisfied in the template--The existence of a `google_analytics` variable in my site configuration. I need to figure out what, in the 
beautiful-jekyll template, is requiring this Google Analytics script in the `_include` directory. 

I was able to grep for "google_analytics.html" from the root directory of my project and found that `_includes/head.html` was the only file that would 
be including the Google Analytics script. In order to connect the OOTB GA behavior with the cookie-consent collection work, I should simply need to cut 
(remove) that include from the `_includes/head.html` file and paste it into the `_includes/cookie-consent.html` file from before--particularly where we 
had previously commented out the includes.

After some simple edits, my header html has no mention of GA and my `cookie-consent.html` has been updated to have:

{% raw %}
```javascript
    if(readCookie('cookie-notice-dismissed')=='true') {
	  {% include google_analytics.html %}
    } else {
        document.getElementById('cookie-notice').style.display = 'block';
    }
```
{% endraw %}

When I configure my Google Analytics account and am able to set the `site.google_analytics` property, GA should only 
load if a visitor explicitly accepts the cookie policy. To really tidy things up, I should create `_/includes/consent-collected-scripts.html` and have that be the only
include code block where consent was granted in `cookie-consent.html` more closely adhering to the [single responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle) 
and putting the changes we would need to make in the future into a simpler file...But, that's not something I'm going to do today.

Now that we have Google Analytics only loading if 3rd part scripts have been approved, we are ready to move on the cookie-consent landing page work.

## Cookie-Consent Landing Page & Banner Links

We are approaching the tail-end of our project today, all that remains is setting up a landing page and updating the button link on the cookie-consent banner 
to point to that page. This way, our site visitors can get a little more information about the intent behind the usage of Google Analytics.

### Landing Page
I created a simple privacy policy explaining some of the technology used to run johnsosoka.com and what I intend to use Google Analytics
tracking for and make sure it is `layout: page`. Now we have a resource that we can perma-link to in the consent collection banner. You could easily infer the markup by viewing the 
page [here](/privacy/index.html)


### Updating the "More Info" Button
If you gave your privacy policy a name other than `privacy.md` OR if for some reason your S3 bucket isn't identifying `index.html` files inside of folders & serving them automatically
you can update the link the `cookie-consent.html`. Mine was updated to have `<a href="/privacy/index.html ...` instead of `<a href="/privacy...` I added the `...` to indicate that this is 
a snippet of a much larger string. 

## Wrap Up 
At this point my site should be configured so that Google Analytics is only loaded if a user consents to the usage of 3rd party cookies & scripts.

I still need to do some reconfiguring of my Google Analytics account before making GA live on my site, but I did want to take some time and set up the infrastructure
for it on the blog while I had some spare time this morning. If I flip all the switches to make this go live and it fails, luckily my site isn't hosted in Europe :)

I will update this post when Google Analytics goes live on johnsosoka.com

## [Update 4/28/20]

In going live the step I had to do in addition to the above was remove the script tags in the `google_analytics.html` include. Once that was resolved, everything worked perfectly.
I did a quick sanity check and ensured that my session didn't show up on the GA dashboard unless I had clicked the approve button.
