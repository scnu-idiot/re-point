package com.idiot.re_point.user.model;

import com.google.cloud.Timestamp;
import lombok.*;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Getter @Setter
@Builder
@AllArgsConstructor @NoArgsConstructor
public class User {
    private String uid;
    private String name;
    private String email;
    private String profileUrl;
    private String address;
    private String loginProvider;
    private Long point;

    // 지역 정보
    private String regionProvince; // province (시/도)
    private String regionCity;     // city (시/군/구)
    private String regionDistrict; // district (읍/면/동)

    private Instant createdAt;
    private Instant updatedAt;

    @SuppressWarnings("unchecked")
    public static User fromMap(String uid, Map<String, Object> m) {
        if (m == null) return null;

        User.UserBuilder b = User.builder()
                .uid(uid)
                .name((String) m.getOrDefault("name", ""))
                .email((String) m.getOrDefault("email", ""))
                .profileUrl((String) m.getOrDefault("profile_url", ""))
                .address((String) m.getOrDefault("address", ""))
                .loginProvider((String) m.getOrDefault("login_provider", ""))
                .point(((Number) m.getOrDefault("point", 0L)).longValue())
                // 지역 필드(snake_case → camelCase)
                .regionProvince((String) m.getOrDefault("region_province", null))
                .regionCity((String) m.getOrDefault("region_city", null))
                .regionDistrict((String) m.getOrDefault("region_district", null));

        // created_at
        Object ca = m.get("created_at");
        if (ca instanceof Timestamp ts) {
            b.createdAt(ts.toDate().toInstant());
        } else if (ca instanceof String s && !s.isEmpty()) {
            try { b.createdAt(Instant.parse(s)); } catch (Exception ignored) {}
        }

        // updated_at
        Object ua = m.get("updated_at");
        if (ua instanceof Timestamp ts) {
            b.updatedAt(ts.toDate().toInstant());
        } else if (ua instanceof String s && !s.isEmpty()) {
            try { b.updatedAt(Instant.parse(s)); } catch (Exception ignored) {}
        }

        return b.build();
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        // 기본 정보
        if (name != null)        map.put("name", name);
        if (email != null)       map.put("email", email);
        if (profileUrl != null)  map.put("profile_url", profileUrl);
        if (address != null)     map.put("address", address);
        if (loginProvider != null) map.put("login_provider", loginProvider);
        map.put("point", point == null ? 0L : point);

        // 지역 정보(snake_case로 저장)
        if (regionProvince != null) map.put("region_province", regionProvince);
        if (regionCity != null)     map.put("region_city", regionCity);
        if (regionDistrict != null) map.put("region_district", regionDistrict);

        // Firestore 저장은 Timestamp로
        map.put("created_at",
                createdAt == null ? null :
                        Timestamp.ofTimeSecondsAndNanos(createdAt.getEpochSecond(), createdAt.getNano()));
        map.put("updated_at",
                updatedAt == null ? null :
                        Timestamp.ofTimeSecondsAndNanos(updatedAt.getEpochSecond(), updatedAt.getNano()));
        return map;
    }
}