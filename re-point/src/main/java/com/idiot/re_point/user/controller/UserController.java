package com.idiot.re_point.user.controller;

import com.idiot.re_point.user.dto.UpdateUserRequest;
import com.idiot.re_point.user.dto.UpsertUserRequest;
import com.idiot.re_point.user.dto.UserDto;
import com.idiot.re_point.user.dto.UpdateRegionRequest;
import com.idiot.re_point.user.model.User;
import com.idiot.re_point.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.idiot.re_point.user.dto.RegionUpdateRequest;


import java.util.concurrent.ExecutionException;


@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** 사용자 단건 조회 */
    @GetMapping("/{uid}")
    public ResponseEntity<?> getUser(@PathVariable String uid) throws ExecutionException, InterruptedException {
        User u = userService.getByUid(uid);
        if (u == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(UserDto.from(u));
    }

    /** 사용자 생성/수정(Upsert) */
    @PutMapping("/{uid}")
    public ResponseEntity<?> upsertUser(@PathVariable String uid, @RequestBody UpsertUserRequest req)
            throws ExecutionException, InterruptedException {

        User u = User.builder()
                .uid(uid)
                .name(req.getName())
                .email(req.getEmail())
                .profileUrl(req.getProfileUrl())
                .address(req.getAddress())
                .loginProvider(req.getLoginProvider())
                .point(0L) // 최초 0포인트
                .build();

        userService.upsert(uid, u);
        return ResponseEntity.ok().body("{\"result\":\"OK\"}");
    }


    /** 사용자 삭제(회원 탈퇴) */
    @DeleteMapping("/{uid}")
    public ResponseEntity<?> deleteUser(@PathVariable String uid)
            throws ExecutionException, InterruptedException {
        userService.delete(uid);
        return ResponseEntity.noContent().build();
    }

    /** 사용자 프로필 부분 업데이트 */
    @PatchMapping("/{uid}")
    public ResponseEntity<?> patchUser(@PathVariable String uid,
                                       @RequestBody UpdateUserRequest req)
            throws ExecutionException, InterruptedException {

        User updated = userService.updateUser(uid, req);
        if (updated == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(UserDto.from(updated));
    }
    @PatchMapping("/{uid}/region")
    public ResponseEntity<?> updateRegion(
            @PathVariable String uid,
            @RequestBody RegionUpdateRequest req
    ) throws ExecutionException, InterruptedException {
        String address = String.join(" ", req.getProvince(), req.getCity(), req.getDistrict());
        userService.updateRegion(uid, req.getProvince(), req.getCity(), req.getDistrict(), address);
        return ResponseEntity.ok(UserDto.from(userService.getByUid(uid)));
    }


}