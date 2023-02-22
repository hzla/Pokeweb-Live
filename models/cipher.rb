
class Cipher



	def self.encrypt pw
		key = ENV["KEY"]
		crypt = ActiveSupport::MessageEncryptor.new(key)
		crypt.encrypt_and_sign(pw)
	end

	def self.auth? rom_name, pw 
		key = ENV["KEY"]
		if pw == ENV["KEY"]
			return true
		end
		crypt = ActiveSupport::MessageEncryptor.new(key)

		rom_pw = SessionSettings.get "pw", rom_name
		decrypted = crypt.decrypt_and_verify(rom_pw)
		# binding.pry
		pw == decrypted
	end

end