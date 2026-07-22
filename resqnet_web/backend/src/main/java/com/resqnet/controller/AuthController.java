package com.resqnet.controller;

import com.resqnet.model.User;
import com.resqnet.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, String> request) {
        String fullName = request.get("fullName");
        String email = request.get("email");
        String username = request.get("username");
        String password = request.get("password");
        String phone = request.get("phone");

        if (username == null || username.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Username, Email, and Password are required."));
        }

        if (userRepository.existsByUsername(username.trim())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Username is already taken."));
        }

        if (userRepository.existsByEmail(email.trim())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Email is already registered."));
        }

        User user = new User();
        user.setFullName(fullName != null ? fullName.trim() : "");
        user.setEmail(email.trim().toLowerCase());
        user.setUsername(username.trim().toLowerCase());
        user.setPassword(password); // In production, hash with BCrypt
        user.setPhone(phone != null ? phone.trim() : "");

        User savedUser = userRepository.save(user);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Registration successful!");
        response.put("user", sanitizeUser(savedUser));

        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@RequestBody Map<String, String> request) {
        String identifier = request.get("usernameOrEmail");
        String password = request.get("password");

        if (identifier == null || identifier.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Username/Email and Password are required."));
        }

        String searchStr = identifier.trim().toLowerCase();
        Optional<User> userOpt = userRepository.findByUsernameOrEmail(searchStr, searchStr);

        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Account not found with provided credentials."));
        }

        User user = userOpt.get();
        if (!user.getPassword().equals(password)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid password."));
        }

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Login successful!");
        response.put("user", sanitizeUser(user));

        return ResponseEntity.ok(response);
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        String fullName = request.get("fullName");
        String email = request.get("email");
        String phone = request.get("phone");
        String password = request.get("password");

        if (username == null || username.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Username is required to identify account."));
        }

        Optional<User> userOpt = userRepository.findByUsername(username.trim().toLowerCase());
        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "User not found."));
        }

        User user = userOpt.get();

        if (email != null && !email.trim().isEmpty() && !email.trim().toLowerCase().equals(user.getEmail())) {
            if (userRepository.existsByEmail(email.trim().toLowerCase())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Email is already taken by another account."));
            }
            user.setEmail(email.trim().toLowerCase());
        }

        if (fullName != null) user.setFullName(fullName.trim());
        if (phone != null) user.setPhone(phone.trim());
        if (password != null && !password.trim().isEmpty()) user.setPassword(password);

        User savedUser = userRepository.save(user);

        return ResponseEntity.ok(Map.of(
            "message", "Profile updated successfully!",
            "user", sanitizeUser(savedUser)
        ));
    }

    @GetMapping("/user/{identifier}")
    public ResponseEntity<?> getUserProfile(@PathVariable String identifier) {
        Optional<User> userOpt = userRepository.findByUsernameOrEmail(identifier, identifier);
        if (userOpt.isPresent()) {
            return ResponseEntity.ok(sanitizeUser(userOpt.get()));
        }
        return ResponseEntity.notFound().build();
    }

    private Map<String, Object> sanitizeUser(User user) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", user.getId());
        map.put("fullName", user.getFullName());
        map.put("username", user.getUsername());
        map.put("email", user.getEmail());
        map.put("phone", user.getPhone());
        map.put("createdAt", user.getCreatedAt());
        return map;
    }
}
