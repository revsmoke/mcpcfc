# Mail Send API Overview

The Mail Send endpoint provides a powerful and intuitive interface for sending email.

The endpoint accepts a JSON object that specifies the details of the email(s) to be sent. This includes not only the basic elements like the sender, recipient, subject, and content, but also more advanced features like personalizations, attachments, and dynamic templates.

## Base URL

SendGrid's v3 Web API uses `https://api.sendgrid.com` for global users and subusers and `https://api.eu.sendgrid.com` for regional subusers in the EU.

## Authentication and authorization

The Mail Send API uses standard Twilio Sendgrid [API Keys](/docs/sendgrid/ui/account-and-settings/api-keys) for authentication and authorization.

If you are new to Twilio SendGrid API keys, see the API key docs to [create an API key](/docs/sendgrid/ui/account-and-settings/api-keys#creating-an-api-key).

The Twilio SendGrid v3 APIs expect the key to be passed as a Bearer Token in an Authorization header. See [**How to Use the SendGrid v3 API**](/docs/sendgrid/api-reference/how-to-use-the-sendgrid-v3-api/authentication) for instructions.

## General Mail Send concepts and usage

### Schedule a send

If you have the flexibility, it's best to schedule mail for off-peak times. Most emails are scheduled and sent at the top of the hour or half hour.

Scheduling email to avoid peak times, for example, scheduling at 10:53 rather than 11:00, can result in lower deferral rates due to the reduced traffic during off-peak times.

### Dynamic Templates and Handlebars

In addition to passing plain text or raw HTML to SendGrid to construct your messages, you can make use of our Dynamic Templates. See [**How to Send an Email with Dynamic Templates**](https://docs.sendgrid.com/ui/sending-email/how-to-send-an-email-with-dynamic-templates) for more information about adding templates and dynamic data to your emails.

### Mail Body Compression

Mail body compression is available to some high volume accounts. Mail body compression works by setting up a JSON payload as defined in the [Mail Send endpoint reference](/docs/sendgrid/api-reference/mail-send/mail-send), then compressing it with gzip (the gzip file can be no more than 30mb).

> \[!NOTE]
>
> Gzip will take the JSON payload and compresses it into a gzip file. This means that anything in the JSON payload including the attachments will be compressed. The compressed data must also be less than the 30MB maximum for the email with headers, body, and attachments.

#### Use mail body compression

1. Submit a [request to support](https://support.sendgrid.com/hc/en-us) to have gzip enabled on your account.
2. Once gzip is enabled, add a `Content-Encoding` header, with a value of `gzip`.
   1. `Content-Encoding: gzip`
3. Send the gzip as a data-binary.
   1. `--data-binary '@data.json.gz'`

### Multiple Reply-To Emails

Using `reply_to_list` allows senders to include more than one recipient's email address to receive reply messages from the recipient of the email.

#### Usage Considerations

* The `reply_to` and `reply_to_list` properties are mutually exclusive. If both are used, the API call will be rejected.
* The `reply_to_list` object, when used, must have at least an `email` property and may also contain a `name` property.
* Each email address in the `reply_to_list` should be unique.
* There is a limit of 1,000 `reply_to_list` emails per Mail Send request.
* In SMTP calls, we will omit any invalid emails.

## Limitations

There are several rate limitations and restrictions that you should be aware of when using the v3 Mail Send endpoint.

* The total size of your email, including attachments, must be less than 30MB.
* The total number of recipients must be no more than 1,000. This includes all recipients defined within the `to`, `cc`, and `bcc` parameters, across each object that you include in the `personalizations` array.
* The total length of custom arguments must be less than 10,000 bytes.
* Unicode encoding is not supported for the `from` field.

For more specific, parameter-level requirements and limitations, please refer to the [Mail Send endpoint documentation](/docs/sendgrid/api-reference/mail-send/mail-send).

## Validation

Whenever you make a request to the v3 Mail Send endpoint, your JSON payload is validated before your email is sent. If there are any errors, SendGrid will attempt to identify and return as many issues as possible for each request. For more information, please read our [error documentation](/docs/sendgrid/api-reference/mail-send/errors).

## Additional resources

### Onboarding guide

For a full-featured guide to ensure you build your email program on a solid foundation, see the [Email API Onboarding guide](/docs/sendgrid/onboarding/email-api).

### Email API quickstarts

Jump to an email quickstart in your programming language of choice to implement the Mail Send API.

* [C#](/docs/sendgrid/for-developers/sending-email/email-api-quickstart-for-c)
* [Go](/docs/sendgrid/for-developers/sending-email/quickstart-go)
* [Java](/docs/sendgrid/for-developers/sending-email/email-quickstart-for-java)
* [Node.js](/docs/sendgrid/for-developers/sending-email/quickstart-nodejs)
* [PHP](/docs/sendgrid/for-developers/sending-email/quickstart-php)
* [Python](/docs/sendgrid/for-developers/sending-email/quickstart-python)
* [Ruby](/docs/sendgrid/for-developers/sending-email/quickstart-ruby)

### SDKs and tools

See our open-source SDKs and tools to integrate with SendGrid.

* [C#](https://github.com/sendgrid/sendgrid-csharp)
* [Go](https://github.com/sendgrid/sendgrid-go)
* [Java](https://github.com/sendgrid/sendgrid-java)
* [Node.js](https://github.com/sendgrid/sendgrid-nodejs)
* [PHP](https://github.com/sendgrid/sendgrid-php)
* [Python](https://github.com/sendgrid/sendgrid-python)
* [Ruby](https://github.com/sendgrid/sendgrid-ruby)
* [OpenAPI specification](https://github.com/twilio/sendgrid-oai)

### More than sending email

See the rest of our [API reference](/docs/sendgrid/api-reference) for more information on how to use the SendGrid v3 Web API's additional features and endpoints.
