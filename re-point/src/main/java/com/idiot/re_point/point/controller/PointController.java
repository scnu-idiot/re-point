package com.idiot.re_point.point.controller;

import com.idiot.re_point.point.dto.PointEarnEventRequest;
import com.idiot.re_point.point.dto.PointEarnInviteRequest;
import com.idiot.re_point.point.dto.PointEarnReceiptRequest;
import com.idiot.re_point.point.dto.PointHistoryDto;
import com.idiot.re_point.point.service.PointService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/points")
@RequiredArgsConstructor
public class PointController {

    private final PointService pointService;

    /** 영수증 인증 적립(고정 100) */
    @PostMapping("/earn/receipt/{uid}")
    public ResponseEntity<Map<String, Object>> earnByReceipt(
            @PathVariable String uid,
            @RequestBody PointEarnReceiptRequest req
    ) throws ExecutionException, InterruptedException {
        long balance = pointService.earnByReceipt(uid, req);
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    /** 친구 초대 적립(고정 500) */
    @PostMapping("/earn/invite/{uid}")
    public ResponseEntity<Map<String, Object>> earnByInvite(
            @PathVariable String uid,
            @RequestBody PointEarnInviteRequest req
    ) throws ExecutionException, InterruptedException {
        long balance = pointService.earnByInvite(uid, req);
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    /** 이벤트 참여 적립(요청 amount 사용) */
    @PostMapping("/earn/event/{uid}")
    public ResponseEntity<Map<String, Object>> earnByEvent(
            @PathVariable String uid,
            @RequestBody PointEarnEventRequest req
    ) throws ExecutionException, InterruptedException {
        long balance = pointService.earnByEvent(uid, req);
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    /** 히스토리 조회 (source 필터: all|receipt|invite|event) */
    @GetMapping("/history/{uid}")
    public ResponseEntity<List<PointHistoryDto>> history(
            @PathVariable String uid,
            @RequestParam(defaultValue = "all") String source,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String before
    ) throws ExecutionException, InterruptedException {
        Instant beforeTs = (before == null || before.isBlank()) ? null : Instant.parse(before);
        return ResponseEntity.ok(pointService.history(uid, source, limit, beforeTs));
    }
}