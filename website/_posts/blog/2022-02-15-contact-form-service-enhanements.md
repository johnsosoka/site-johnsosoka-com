---
layout: post
title: Enhancing My Blogs Contact Form & Contact Listener Service
category: blog
tags: jquery ajax python javascript housekeeping programming cse json Udemy event http forms aws lambda api-gateway
---

I’m certain that I’ve mentioned in previous posts that I am _not_ a client-side engineer. I have near zero experience with front-end work (which is why I’m taking courses & practicing on my website.) If you saw my post on handling [contact form submissions](/blog/2021/12/24/contact-me-form-services.html) _and_ you have client-side experience, then you probably saw just how clunky my front-end work is.

In my previous post, I had used an HTML form & form submit. This resulted in a poor user experience & fair bit of bloated backend code to parse the submission. As implemented, upon form submit, the user would be redirected to the backend service. A more familiar and modern experience would have had the request fire in the background upon submit.

Now that I have taken an introductory Javascript course ([course notes here](/note/udemy/js-jquery-course/2022-01-29-the-complete-js-jsquery-course.html)) I have a better understanding of how to handle form submissions in a more familiar and modern way.

## Long-Term Plan

My contact-me form has been getting put to work—particularly by some bots. I had expected this to some extend & luckily, it isn’t terribly frequently. Before setting up CAPTCHA (which is inevitable) I would like to build out contact spam filter as a backend service from scratch. While I will not be building out that functionality today, I will be making some adjustments to my existing [contact-me-listener-svc](https://github.com/johnsosoka/jscom-contact-services/tree/main/contact-me-listener-svc) which will help to set my future project up for success.

## Today’s Plan

Today have three objectives.

* Modify the existing contact form to submit a json payload containing the contact-form contents in the body of the request to the `contact-me-listener-svc` by way of api-gateway.
* Adjust the `contact-me-listener-svc` to handle the new payload—This will result in the removal of lots of code.
* Add more fields to the contact-me model object—These fields may include IP address, user-agent, etc. This will aid the spam filter project in the future.

Now that we have an idea of where we are heading & why, let’s begin!

## Contact Form Improvements.

My website is created using the Jekyll static site generator. Jekyll has a concept of `_includes` which are HTML & Javascript snippets which can be included/stitched together into usable webpages.

This is what we are starting with:

```html
<form form id="FormID" action="{{ site.contact.api.url }}" method="{{ site.contact.api.method }}" >
  <ul>
    <li>
      <label for="name">Name:</label>
      <input type="text" id="name" name="user_name">
    </li>
    <li>
      <label for="mail">E-mail:</label>
      <input type="email" id="mail" name="user_email">
    </li>
    <li>
      <label for="msg">Message:</label>
      <textarea id="msg" name="user_message"></textarea>
    </li>
    <li class="button">
      <input type="submit" value="Send your message">
    </li>
  </ul>
</form>
```

The action & method values are expanded from variables set elsewhere in the Jekyll configuration. These will be used in our changes. First things first, I’m going to need to set up an event listener for the submit button & write a function to pull the values for these fields and place them into a JSON string for submission.

### Building the Contact Payload

First, I need to modify the HTML so that the original form submission doesn’t occur. Additionally, I will include jquery to ease this whole process.

```html
<div id="contactMeForm">
  <ul>
    <li>
      <label for="name">Name:</label>
      <input type="text" id="name" name="user_name">
    </li>
    <li>
      <label for="mail">E-mail:</label>
      <input type="email" id="mail" name="user_email">
    </li>
    <li>
      <label for="msg">Message:</label>
      <textarea id="msg" name="user_message"></textarea>
    </li>
    <li class="button">
      <input type="submit"  id="contact_submit" value="Send your message">
    </li>
  </ul>
</div>

<!-- TODO host own jquery -->

<script src="https://code.jquery.com/jquery-3.6.0.js" integrity="sha256-H+K7U5CnXl1h5ywQfKtSj8PCmoN9aaq30gDh27Xc0jk=" crossorigin="anonymous"></script>

```
While I develop I’m using the hosted jquery, later I will host and embed throughout my site properly—please don’t give me too much grief `:)`.

```javascript
<script>
  function buildPayload() {
    var contactMePayload = {
      contactName : $('#name').val(),
      contactEmail : $('#mail').val(),
      contactMessage : $('#msg').val()
    };

    return JSON.stringify(contactMePayload);
  }
</script>
```

This function should be fairly straightforward. It fetches each contact-form input by their ID via jquery’s ID selector `#`. You can see in the above that I’m building out a javascript object as we’re selecting the value for these text inputs. Once the object is built, I convert it to a string with the `JSON.stringify` method.

Next up, we need a mechanism to send this to our backend service.

```javascript
  function submitContact(payload) {
    $.ajax({
      url : "{{ site.contact.api.url }}",
      type: "{{ site.contact.api.method }}",
      dataType: "json",
      data: payload,
      success: function(data){
        console.log(data);
        alert('succes!')
      },
      error: function(){
        console.log("Error in the request");
        alert('something went wrong.');
      }
    });
  }
```

This function accepts the payload as a parameter, and then posts to the url `{{ site.contact.api.url }}` which gets expanded later when Jekyll generates site artifacts.

Finally, we need to se up an event listener for the submit button, which will call the two methods above when the user clicks submit on the contact form.

```javascript
$('#contact_submit').click(function() {
    var payload = buildPayload();
    console.log(payload);
    submitContact(payload);

  });
```

Now we should be ready to revisit and adjust the backend `contact-me-listener-svc`

### Adjusting the Backend Service

The first thing I want to do is verify that the code I just wrote is indeed delivering a json payload in the body of the request. In addition to that, I want a refresher on the other fields provided by api-gateway to get a better idea of what the future spam filter project could use.

I already have my services wired up—Since my site gets very little traffic, I’m testing in production. First, I adjust the existing lambda function in place to simple print out the event.

Here is my _temporary_ modified lambda handler code—remember, this is just to gather some additional details about the event and ensure that our request is properly formed:

```python
from app.application import Application
import json

def lambda_handler(event, context):
    print(event)
    app = Application()
    response_body = {"hello" : "world"}
    return {
        'statusCode': 200,
        'body': json.dumps(response_body)
    }
```

You can see here, I’m really just receiving the event & printing it. The following is the cleaned up output of that event:

```python
{
    'version': '2.0',
    'routeKey': 'POST /services/form/contact',
    'rawPath': '/services/form/contact',
    'rawQueryString': '',
    'headers': {
        'accept': 'application/json, text/javascript, */*; q=0.01',
        'accept-encoding': 'gzip, deflate, br',
        'accept-language': 'en-US,en;q=0.9',
        'content-length': '85',
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'host': 'api.johnsosoka.com',
        'origin': 'http://localhost:4000',
        'referer': 'http://localhost:4000/',
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15',
        'x-amzn-trace-id': 'Root=1-62097b36-486a181638d037d5090a342f',
        'x-forwarded-for': '152.73.127.80',
        'x-forwarded-port': '443',
        'x-forwarded-proto': 'https'
    },
    'requestContext': {
        'accountId': '033448470137',
        'apiId': 'k6mta3dh76',
        'domainName': 'api.johnsosoka.com',
        'domainPrefix': 'api',
        'http': {
            'method': 'POST',
            'path': '/services/form/contact',
            'protocol': 'HTTP/1.1',
            'sourceIp': '152.73.127.80',
            'userAgent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15'
        },
        'requestId': 'NgAwjik1IAMEMeA=',
        'routeKey': 'POST /services/form/contact',
        'stage': '$default',
        'time': '13/Feb/2022:21:42:14 +0000',
        'timeEpoch': 1644788534516
    },
    'body': 'eyJjb250YWN0TmFtZSI6ImpvaG4iLCJjb250YWN0RW1haWwiOiJqb2huQHRlc3QuY29tIiwiY29udGFjdE1lc3NhZ2UiOiJ0ZXN0IG1lc3NhZ2UifQ==',
    'isBase64Encoded': True
}
```

This looks as I would expect it. Nothing present in the `rawQueryString` field and a body is present on the event. You may have noticed that the body doesn’t particularly look like JSON—It’s base64 encoded. Running this through an online base64 decoder, I can see that the decoded body is:

```json
{
"contactName": "john",
"contactEmail": "john@test.com",
"contactMessage": "test message"
}
```

The only fields in the event which appear to be helpful for a spam filter in the future are the `sourceIp` and potentially that `userAgent`. I fetch these values and add them to the contact-me model, which will be published to a pre-existing contact-me SNS topic.

So much code will be gutted from the original service that this will practically be a rewrite. Since I did not provide too many details on the python portion of this project in a previous article—I will walk through redevelopment step-by-step.

The `contact-me-listener-svc` will need to:

* Decode the body of the event (if base64 encoded)
* Validate the contact-me payload fields—Return validation errors as appropriate.
* Add the sourceIP Address & userAgent to the contact model, which is then submitted to a pre-existing SNS topic.


### From the Top

In AWS lambda, when a qualifying event occurs and the lambda is invoked, your main handler method will be invoked with an event & context parameter. In my lambda implementations, I hide the rest of the application behind something of a facade in this handler method.

One reason is that objects initialized outside the main lambda handler are “frozen” and can be “thawed” by the AWS environment managing the execution code. This can help increase performance of the lambda during back-to-back invocations, and can also allow for some other neat tricks (which we will not be getting into in this article.) If you are curious, check out— [here](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-context.html).

```python
from app.application import Application


def lambda_handler(event, context):
app = Application()
return app.handle(event)
```

As you can see, I initialize the imported Application class & pass the event to it for further processing. The event passed here is structured just like the JSON above, from my earlier executions.

#### Extracting Important Fields

My main Application class is going to need a handful of utility functions & classes available to do all the processing necessary for this service to run. The first utility class I'll set up is an EventProccessingUtil—this class will be loaded with static methods and assist in extracting relevant fields from the event payload.

```python
import base64
import json


class EventProcessingUtil:

    @staticmethod
    def extract_relevant_fields(event):
        """
        Extracts request body, decodes if necessary & combines with contact identifiers from the EventContext
        :param event:
        :return:
        """
        event_body = EventProcessingUtil._extract_request_body(event)
        identifiers = EventProcessingUtil._extract_request_identifiers(event)

        # combine dictionaries
        event_body.update(identifiers)
        return event_body

    @staticmethod
    def _decode_body_to_dict(base64_encoded_body) -> dict:
        decoded_body = base64.b64decode(base64_encoded_body).decode("utf-8")
        return json.loads(decoded_body)

    @staticmethod
    def _extract_request_body(event) -> dict:
        """
        Extracts request body, base64 decodes if necessary and returns a dictionary.

        :param: event
        :return: dict
        """
        event_body = ""
        if event["isBase64Encoded"]:
            event_body = EventProcessingUtil._decode_body_to_dict(event["body"])
        else:
            event_body = json.loads(event["body"])

        return event_body

    @staticmethod
    def _extract_request_identifiers(event):
        """
        Method to fetch fields which could aid a spam filter.
        :param: event
        :return:
        """
        request_identifiers = {"userAgent": event["requestContext"]["http"]["userAgent"],
                              "sourceIP": event["requestContext"]["http"]["sourceIp"]}

        return request_identifiers
```


This utility class only contains one “public” method—python doesn’t really have enforced private methods, but private methods can be indicated with `_` or `__` prepending the name. The public method `extract_relevant_fields` first calls a helper method that extracts the body of the request. Note that this helper method will base64 decode it, only if the event specifies that it is base64 encoded.

After the body of the request has been extracted from the event, we need to fetch the request identifiers from the event. Particularly the IP address & user agent, which are retrieved from the method `_extract_request_identifiers` the last interesting thing that occurs in this helper class is:

```python
event_body.update(identifiers)
```

Here I’m simply merging the two dictionaries into a single dictionary, by updating the first dictionary with the second. In newer version of python a union operator has been introduced, we should soon be able to merge dictionaries as.

`dict3 = dict1|dict2`

#### Validation

The validation on this lambda is pretty straightforward. The only fields that I consider mandatory are `contactEmail` and `contactMessage`, I do validate that `contactName` is present, but I do not fail validation if it’s not present.

```python
import logging
logger = logging.getLogger("app.validator.ContactEventValidator")


class ContactEventValidator:

    @staticmethod
    def validate_event(payload_event: dict) -> bool:
        is_valid = True

        if "contactEmail" not in payload_event:
            is_valid = False
            logger.warning("user_email missing from contact submission")
        if "contactMessage" not in payload_event:
            is_valid = False
            logger.warning("user_message missing from contact submission")
        if "contactName" not in payload_event:
            # Don't fail if name missing, just log it.
            logger.warning("user_name not present in contact submission...")
        return is_valid
```



#### SNS Publisher

My SNS publisher is basically ripped directly from the amazon example documents, it uses the boto3 library to create an SNS client and then publishes to a specified topic ARN. Note—This topic ARN is fetched from an environment variable which is set via terraform with the lambda is created.

```python
import boto3
import json


class SNSPublisher:
    def __init__(self):
        self._sns_client = boto3.client("sns")

    def publish_message(self, topic_arn, message_json):
        response = self._sns_client.publish(
            TargetArn=topic_arn,
            Message=json.dumps({'default': message_json}),
            MessageStructure='json'
        )
```



#### Application

Here is where it all gets tied together, in my application.py file. The handler function at the top of this section acts as a facade for this:

```python
import logging
from app.common.constants import (TOPIC_ARN_KEY,
VALIDATION_FAILURE_MESSAGE,
FAILURE_EXECUTION,
PUBLISH_FAILURE_MESSAGE,
SUCCESS_EXECUTION,
PUBLISH_SUCCESS_MESSAGE
)
from app.validator.contact_event_validator import ContactEventValidator
from app.publisher.sns_publisher import SNSPublisher
from app.util.event_processing_util import EventProcessingUtil
import json
import os

logger = logging.getLogger("app.Application")
logger.setLevel(logging.DEBUG)


class Application:

    def __init__(self):
        self._contact_event_validator = ContactEventValidator()
        self._sns_publisher = SNSPublisher()
        self._topic_arn = os.environ.get(TOPIC_ARN_KEY)

    def handle(self, event):
        """Handle form submit event

        process, validate & submit event to SNS.
        :param: event
        :return:
        """
        logger.debug("handling event {}".format(str(event)))

        contact_event = EventProcessingUtil.extract_relevant_fields(event)

        # Validate Event
        valid_event = self._contact_event_validator.validate_event(contact_event)

        if not valid_event:
            logger.warning("Validation failure, preparing failure response.")
            return self.prepare_message(400, FAILURE_EXECUTION, VALIDATION_FAILURE_MESSAGE)

        try:
            self._sns_publisher.publish_message(self._topic_arn, json.dumps(contact_event))
        except Exception as e:
            logger.error("Exception publishing to topic_arn {arn}".format(arn=self._topic_arn))
            logger.error(e)
            return self.prepare_message(500, FAILURE_EXECUTION, PUBLISH_FAILURE_MESSAGE)

        return self.prepare_message(200, SUCCESS_EXECUTION, PUBLISH_SUCCESS_MESSAGE)

    @staticmethod
    def prepare_message(status_code: int, execution_status, message="none"):
        response_body = {"execution_status": execution_status,
                         "message:": message}

        return {
            'statusCode': status_code,
            'body': json.dumps(response_body)
        }
```



As you can see, the application configures itself by fetching the topic ARN from the environment upon initialization—Additionally it creates an SNS publisher and stores it as an instance variable.

When this executes, we simply extract relevant fields (base64 decoding if necessary), validate & then publish to an SNS topic.

When I make a submission from the modified contact form, I do indeed get an e-mail with an event payload as expected—here’s what it looks like (I formatted the JSON portion for readability):

```JSON
{
"contactName": "john",
"contactEmail": "john@test.com",
"contactMessage": "another TEST MESSAGE!!",
"userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
"sourceIP": "152.73.127.80"
}

--
If you wish to stop receiving notifications from this topic, please click or visit the link below to unsubscribe:
<REDACTED>
```

## Conclusion

Today was quite an adventure. We updated behavior on the contact form for a slightly more modern experience & helped pave some road for creating a spam filter in the future by adding sourceIP and userAgent to the contact event context. Stay tuned for further refinements to this project, including the contact-event-sender & spam filter.
