#!/usr/bin/env ruby

# Caesar Cipher class for encrypting and decrypting messages
class CaesarCipher
    # Constructor: initializes the shift value for encryption/decryption
    def initialize(shift)
        @shift = shift  # Store the shift value (instance variable)
    end

    # Public method: encrypts a message using the Caesar cipher
    def encrypt(message)
        cipher(message, @shift)  # Call cipher with positive shift
    end

    # Public method: decrypts a message using the Caesar cipher
    def decrypt(message)
        cipher(message, -@shift)  # Call cipher with negative shift to reverse
    end

    # Private section: methods below can only be called within this class
    private

    # Private method: performs the actual Caesar cipher shift
    def cipher(message, shift)
        result = ""  # Initialize empty string to store the result

        # Loop through each character in the message
        message.each_char do |c|
        # Check if character is uppercase letter (A-Z)
        if c >= 'A' && c <= 'Z'
            # Convert to number (0-25), add shift, wrap around with %, convert back to letter
            result << ((c.ord - 'A'.ord + shift) % 26 + 'A'.ord).chr
        # Check if character is lowercase letter (a-z)
        elsif c >= 'a' && c <= 'z'
            # Same logic as uppercase but for lowercase letters
            result << ((c.ord - 'a'.ord + shift) % 26 + 'a'.ord).chr
        # If not a letter (space, punctuation, etc.)
        else
            result << c  # Keep the character unchanged
        end
        end

        result  # Return the encrypted/decrypted result
    end
end