module PasswordDigest

  def has_password_digest
    attr_reader :password
    validates_confirmation_of :password
    validates_presence_of :password_digest
    include InstanceMethods
  end

  module InstanceMethods
    def as_json(opts = {})
      super(opts.merge(except: [:password_digest]))
    end

    def compute_password_digest(unencrypted_password)
      Digest::MD5.hexdigest([self.name, Carpool::REALM, unencrypted_password].join(':'))
    end

    def password=(unencrypted_password)
      unless unencrypted_password.blank?
        @password = unencrypted_password
        self.password_digest = compute_password_digest(@password)
      end
    end

    def authenticate(unencrypted_password)
       compute_password_digest(unencrypted_password) == self.password_digest
    end
  end

end
