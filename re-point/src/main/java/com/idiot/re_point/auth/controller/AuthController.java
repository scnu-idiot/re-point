package com.idiot.re_point.auth.controller;

import com.idiot.re_point.auth.dto.AuthLoginRequest;
import com.idiot.re_point.user.dto.UserDto;
import com.idiot.re_point.user.model.User;
import com.idiot.re_point.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

/**
 * 소셜 로그인 완료 후 서버 동기화 (검증 없는 버전)
 * - 프론트에서 이미 구글/카카오 로그인 성공 → 프로필 받음
 * - 서버는 Firestore에 사용자 upsert + 최신 사용자 반환
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/login/{uid}")
    public ResponseEntity<?> login(@PathVariable String uid,
                                   @RequestBody AuthLoginRequest req)
            throws ExecutionException, InterruptedException {

        // 서버가 보관할 사용자 스냅샷 구성
        User u = User.builder()
                .uid(uid)
                .name(req.getName())
                .email(req.getEmail())
                .profileUrl(req.getProfileUrl())
                .address(req.getAddress())
                .loginProvider(req.getLoginProvider()) // "google" | "kakao"
                .point(0L) // 최초 가입 시 0 포인트 (기존 문서가 있으면 유지 로직은 서비스에 있음)
                .build();

        // upsert 수행
        userService.upsert(uid, u);

        // 최신 사용자 조회 후 내려주기
        User saved = userService.getByUid(uid);
        return ResponseEntity.ok(UserDto.from(saved));
    }
}