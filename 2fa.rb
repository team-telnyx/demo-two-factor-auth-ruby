require 'date'
require 'sinatra'
require 'telnyx'
require 'securerandom'
require 'yaml'

$config = YAML.safe_load(File.open('config.yml').read)
Telnyx.api_key = $config['API_KEY']


class TokenStorage
    @@tokens = {}
    def self.addToken(token, phoneNumber)
        @@tokens[token] = {
            phone_number: phoneNumber,
            last_updated: DateTime.now,
            token: token.upcase
        }
    end

    def self.tokenIsValid(token)
        return @@tokens.key?(token)
    end

    def self.clearToken(token)
        @@tokens.delete(token.upcase)
    end
end

get '/' do
  erb :index
end



post '/request' do
    phoneNumber = params['phone']
                    .gsub('-','').gsub('.','')
                    .gsub('(','').gsub(')','')
                    .gsub(' ','')
    generatedToken = getRandomTokenHex($config["TOKEN_LENGTH"])
    TokenStorage.addToken(generatedToken, phoneNumber)

    Telnyx::Message.create(
        from: "#{$config["COUNTRY_CODE"]}#{$config["FROM_NUMBER"]}",
        to: "#{phoneNumber}",
        text:"Your token is #{generatedToken}",
    )

    erb :verify
end

post '/verify' do 
    token = params['token']

    if TokenStorage.tokenIsValid(token)
        TokenStorage.clearToken(token)
        erb :verify_success
    else
      erb :verify, locals: {
        display_error: True
      }
    end
end


def getRandomTokenHex(numChars)
   return SecureRandom.hex(numChars) 
end

    



