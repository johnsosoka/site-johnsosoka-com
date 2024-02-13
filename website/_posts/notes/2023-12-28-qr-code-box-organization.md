---
layout: post
title: "Organizing Home Storage with Python, QR Codes & Notion"
category: note
tags: notion productivity qr python organization storage home household tech
---

**Edit 02/13/24:** - Now that Notion has released notion.ai, this strategy is even more powerful. I can just ask a bot
inside Notion where my stuff is.

I've had a nomadic couple of years. Having moved about four times in as many years, I've had to pack and unpack my life 
a few times. It's a great way to prune your belongings. It's also a great way to lose track of things.


## The Problem

Over time, the contents of our storage boxes shift. A box that was once full of C++ books may now be full of python books. 
A box that used to contain Playstation 4 games and accessories may someday contain Playstation 5 games and accessories. 
Point being, the more detailed we are about the contents _on the box_ the more likely those details will become innacurate 
over time.

## The Solution

I had been toying with the idea of using QR codes to label boxes for a while. Some time ago, I played around with a python 
library to get an idea of how it worked and what types of information I could encode.

Initially I had thought to simply encode the contents within the QR code, but I realized this would be pointless. I could 
just as easily write the contents on the box. 

The real value would be in having the QR code link to a database that would be updatable.

Additionally, storing box information in a database would allow me to save location details of the box itself. So, I could 
search by contents, identify where the box is located & then go fetch it from my garage.

### Notion

I decided to use [Notion](https://www.notion.so/) as my database. I have been using it for some time and I've enjoyed it.
Plus, I already have the application on my phone, so I can easily scan the QR code which will take me to the Notion page 
for the box I'm working with.

The 1st step is to prepare the notion database. I created a new page with a table that has the following columns:
Name, Tags, Content, QR Code, Type, Location.



### Python & QR Code

Once the database is created an an entry exists, it's time to write some python code:

```python
import qrcode

qr_data = {
    "BX0001": "https://www.notion.so/jsosoka/BX0001-fbe3a46c857d4e36a660ed1db94cb09a?pvs=4",
    "BX0002": "https://www.notion.so/jsosoka/BX0002-c7b91e641e1f4565ba104efec3f50f68?pvs=4",
    "BX0003": "https://www.notion.so/jsosoka/BX0003-3bf5f8b21cb94276a95da590bc97ffaa?pvs=4",
    "BX0004": "https://www.notion.so/jsosoka/BX0004-5e7f9173043c49f396d2489cda1724ba?pvs=4",
    "BX0005": "https://www.notion.so/jsosoka/BX0005-1432526864ea475fade4931b4d16eeca?pvs=4",
    "BX0006": "https://www.notion.so/jsosoka/BX0006-c1d99d3db3a84a7e86432b5914b7e39c?pvs=4",
    "BX0007": "https://www.notion.so/jsosoka/BX0007-731956b5b18f41ad94c44e3642ffff31?pvs=4",
    "BX0008": "https://www.notion.so/jsosoka/BX0008-80cec0b208a940f0a1e77375de1fc137?pvs=4",
    "BX0009": "https://www.notion.so/jsosoka/BX0009-066f4a9ee155414794874a9d9496efd9?pvs=4",
    "BX0010": "https://www.notion.so/jsosoka/BX0010-a14e90dc5b9b40eb8e036161244a0543?pvs=4",
    "BX0011": "https://www.notion.so/jsosoka/BX0011-57cf5e8813d74cb2b342f2aff19bbc9e?pvs=4",
    "BX0012": "https://www.notion.so/jsosoka/BX0012-1beedb8f58b44cf29667471202992754?pvs=4",
    "BX0013": "https://www.notion.so/jsosoka/BX0013-1600ebab14744720a987fff40afd4d49?pvs=4",
    "BX0014": "https://www.notion.so/jsosoka/BX0014-29cad5980f6642419db0c46de0891f14?pvs=4",
    "BX0015": "https://www.notion.so/jsosoka/BX0015-4e5e5f9374a24bad91a43fc86b6f87d7?pvs=4"
}

# Loop through the dictionary and generate QR codes for each entry
for key, url in qr_data.items():
    # Generate QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    qr_image = qr.make_image(fill_color="black", back_color="white")

    # Save the QR code image
    qr_image.save(key + ".png")

    print(f"QR code for {key} generated and saved as '{key}.png'")
```

You'll notice that in the above, I'm creating a dictionary with entries corresponding to each box. The key is the box
name/id and the value is the URL to the Notion page for that box.


## The Result

Once al of the QR codes have been generated, I tossed them into a Microsoft Word document, added a human readable label,
and printed.

![Cutting the Codes](https://media.johnsosoka.com/blog/2023-12-19/IMG_2205.jpeg)

After cutting the codes, I taped them to boxes.

![Cutting pt 2](https://media.johnsosoka.com/blog/2023-12-19/IMG_2208.jpeg)

I spent some time in the garage, with my tablet attaching the QR codes to boxes & updating the database
entries in Notion.

This was a fun project that only took a couple of hours. It was an idea that I had been kicking around for some time, 
ideally it will enable me to find things in my garage without having to dig through boxes. I haven't been using this 
system long enough to know if it will be useful, but I'm optimistic and hope that sharing this will help others.