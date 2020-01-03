require 'date'
require 'sinatra'
require 'telnyx'
require 'securerandom'
require 'yaml'

$config = YAML.safe_load(File.open('config.yml').read)
Telnyx.api_key = $config['YOUR_API_KEY']


class TokeStorage
    @@tokens = {}
    def new()
    end
    def addToken(_token, phoneNumber)
        @@tokens[token] = {
            phone_number: phoneNumber,
            last_updated: DateTime.now,
            token: _token.upcase
        }
    end

    def tokenIsValid(_token)
        return @@tokens.key?(_token.upcase)
    end

    def clearToken(_token)
        @@tokens.delete(_token.upcase)
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
        from: $config["FROM_NUMBER"],
        to: "#{$config["COUNTRY_CODE"]}#{phoneNumber}",
        text:"Your token is #{generatedToken}",
    )
    
    erb :verify

end

get '/verify' do 
    token = params['token']

    if TokenStorage.tokenIsValid(token)
        TokenStorage.clearToken(token)
        erb :verify_sucess
    else
      erb :verify, locals: {
        display_error: True
      }
    end
end


def getRandomTokenHex(numChars)
    return rand(numChars/2).to_s(numChars/2)
end

    



