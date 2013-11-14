# encoding: UTF-8

# Copyright 2011-2013 innoQ Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class User < ActiveRecord::Base
  ROLES = [
    "reader", "editor", "publisher", "administrator"
  ]

  has_secure_password

  validates_length_of :forename, :surname, :within => 2..255
  validates_inclusion_of :role, :in => ROLES
  validates_presence_of :email
  validates_uniqueness_of :email
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def self.default_role
    "reader"
  end

  def valid_password?(password)
    begin
      authenticate(password)
    rescue BCrypt::Errors::InvalidHash
      stretches = 20
      digest  = [password, password_salt].flatten.join('')
      stretches.times {digest = Digest::SHA512.hexdigest(digest)}
      if digest == self.crypted_password
        self.generate_token(:auth_token)
        self.password = self.password_confirmation = password

        # deletes sha512 once user has logged in and updated to bcrypt
        self.crypted_password = self.password_salt = nil

        self.save
        return true
      else
        # If not BCryt password and not old Authlogic SHA512 password Dosn't my user
        return false
      end
    end
  end

  def name
    "#{forename} #{surname}"
  end

  def owns_role?(name)
    self.role == name.to_s
  end

  def to_s
    self.name.to_s
  end

end
