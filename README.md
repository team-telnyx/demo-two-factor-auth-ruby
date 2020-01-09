# Two factor authentication with Telnyx

⏱ **20 minutes build time || Difficulty Level: Intermediate || [Github Repo](https://github.com/team-telnyx/demo-two-factor-auth-ruby)**


## Configuration

Create a `config.cfg` file in your project directory. Flask will load this at startup. First, use [this](https://developers.telnyx.com/docs/v2/messaging/quickstarts/portal-setup) guide to provision an SMS number and messaging profile, and create an API key. Then add those to the config file.

```yaml
API_KEY: 'YOUR_API_KEY'
FROM_NUMBER: 'YOUR_TELNYX_NUMBER'
COUNTRY_CODE: '+1'
TOKEN_LENGTH: 4
```

> **Note:** *This file contains a secret key, it should not be committed to source control.*


## Token Storage

We'll use a class to store tokens in memory for the purposes of this example. In a production environment, a traditional database would be appropriate. Create a class called `TokenStorage` with three methods. This class will store uppercase tokens as keys, with details about those tokens as values, and expose check and delete methods.

```ruby
class TokenStorage
    @@tokens = {}
    def self.addToken(token, phoneNumber)
        @@tokens[token] = {
            phone_number: phoneNumber,
            last_updated: DateTime.now,
            token:        token.upcase
        }
    end

    def self.tokenIsValid(token)
        return @@tokens.key?(token)
    end

    def self.clearToken(_token)
        @@tokens.delete(token)
    end
end
```


## Server initialization

Setup a simple Flask app, load the config file, and configure the telnyx library. We'll also serve an `index.html` page, the full source of this is available on GitHub, but it includes a form that collects a phone number for validation.

```ruby
$config = YAML.safe_load(File.open('config.yml').read)
Telnyx.api_key = $config['YOUR_API_KEY']

get '/' do
  erb :index
end
```


## Token generation

We'll start with a simple method, `get_random_token_hex`, that generates a random string of hex characters to be used as OTP tokens. We'll use the SecureRandom gem for this, as it comes pre-installed in Ruby.

```ruby
def getRandomTokenHex(numChars)
   return SecureRandom.hex(numChars) 
end
```

The `SecureRandom.hex` method accepts a number of bytes, so we need to divide by two and and round up in order to ensure we get enough characters (two characters per byte), and then finally trim by the actual desired length. This allows us to support odd numbered token lengths.

Next, handle the form on the `/request` route. First this method normalizes the phone number.

```ruby
post '/request' do
    phoneNumber = params['phone']
                    .gsub('-','').gsub('.','')
                    .gsub('(','').gsub(')','')
                    .gsub(' ','')
```

Then generate a token and add the token/phone number pair to the data store.

```ruby
    generatedToken = getRandomTokenHex($config["TOKEN_LENGTH"])
    TokenStorage.addToken(generatedToken, phoneNumber)
```

Finally, send an SMS to the device and serve the verification page.

```ruby
    Telnyx::Message.create(
        from: "#{$config["COUNTRY_CODE"]}#{$config["FROM_NUMBER"]}",
        to: "#{phoneNumber}",
        text:"Your token is #{generatedToken}",
    )
    
    erb :verify

end
```


## Token verification

The `verify.html` file includes a form that collects the token and sends it back to the server. If the token is valid, we'll clear it from the datastore and serve the success page.

```ruby
get '/verify' do 
    token = params['token']

    if TokenStorage.tokenIsValid(token)
        TokenStorage.clearToken(token)
        erb :verify_sucess
```

Otherwise, send the user back to the verify form with an error message

```ruby
    else
      erb :verify, locals: {
        display_error: True
      }
    end
end
```


## Finishing up

To start the application, run `ruby 2fa.rb`.
